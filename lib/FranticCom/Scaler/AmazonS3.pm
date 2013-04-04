package FranticCom::Scaler::AmazonS3;

use Moose;
use namespace::autoclean;
use Data::Dumper;
use Digest::SHA qw( sha256_hex );
use Net::Amazon::S3;
use Exception::Class qw( X );
use Imager;
use LWP::UserAgent;

has 'aws_access_key_id' =>      ( is => 'rw', default => $ENV{AWS_ACCESS_KEY_ID} );
has 'aws_secret_access_key' =>  ( is => 'rw', default => $ENV{AWS_SECRET_ACCESS_KEY} );
has 's3_bucket_name' =>         ( is => 'rw', default => $ENV{S3_BUCKET_NAME} );

has 's3' =>         ( is => 'ro', builder => '_build_s3', lazy => 1 );
has 'bucket' =>     ( is => 'ro', builder => '_build_bucket', lazy => 1 );
has 'ua' =>         ( is => 'ro', builder => '_build_ua', lazy => 1 );

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => 'scaler/1.0',
        ssl_opts => {
            SSL_verify_mode => 'SSL_VERIFY_PEER',
        }
    );
    return $ua;
}

sub _build_s3 {
    my ( $self ) = @_;
    Net::Amazon::S3->new({
        aws_access_key_id     => $self->aws_access_key_id,
        aws_secret_access_key => $self->aws_secret_access_key,
        retry                 => 1,
    });
}

sub _build_bucket {
    my ( $self ) = @_;
    $self->s3->bucket($self->s3_bucket_name);
}

sub store : method {
    my ( $self, $src, $name, $metadata, $properties ) = @_;

    my $head = $self->bucket->head_key( $name );
    if ( $head and $head->{'x-amz-meta-src-uri'} eq $src ) {
        my $img_head = $self->ua->head( $src ) || die;
        if (
            $head->{'x-amz-meta-src-last-modified'} and $img_head->header('Last-Modified') and
            $img_head->header('Last-Modified') eq $head->{'x-amz-meta-src-last-modified'}
            or
            $head->{'x-amz-meta-src-etag'} and $img_head->header('ETag') and
            $img_head->header('ETag') eq $head->{'x-amz-meta-etag'}
        ) {
            print STDERR "STORE NOT MODIFIED\n";
            return 'http://'.$self->bucket->bucket.'.s3.amazonaws.com/'.$name;
        }
    }

    my $img_src = $self->ua->get( $src );
    die if $img_src->is_error;

    my ($width,$height,$scale) = (
        $properties->{width}, $properties->{height}, $properties->{scale}
    ) if $properties;

    my $img = Imager->new( data => $img_src->content ) || die Imager->errstr;
    my $img_out;
    if ( $width and $height ) {
        $img->scale( xpixels => $width, ypixels => $height, type => 'max')
            ->crop( width => $width, height => $height )
            ->write( data => \$img_out, type => 'jpeg' )
            || X->throw( error => Imager->errstr );
    } else {
        $img->write( data => \$img_out, type => 'jpeg' )
            || X->throw( error => Imager->errstr );
    }

    my $response = $self->bucket->add_key( $name, $img_out, {
        content_type => 'image/jpeg',
        acl_short => 'public-read',
        'x-amz-meta-src-uri' => $src,
        'x-amz-meta-src-etag' => scalar $img_src->header('ETag'),
        'x-amz-meta-src-date' => scalar $img_src->header('Date'),
        'x-amz-meta-src-last-modified' => scalar $img_src->header('Last-Modified'),
        %{ $metadata || {} },
    }) or X->throw( error => $self->s3->err . ": " . $self->s3->errstr );

    return 'http://'.$self->bucket->bucket.'.s3.amazonaws.com/'.$name;
}

1;

