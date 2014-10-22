package FranticCom::Scaler::AmazonS3;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Digest::SHA qw( sha256_hex );
use Net::Amazon::S3;
use Exception::Class qw( X );
use Imager;
use LWP::UserAgent;
use MIME::Types;

has 'aws_access_key_id' =>      ( is => 'rw', default => $ENV{AWS_ACCESS_KEY_ID} );
has 'aws_secret_access_key' =>  ( is => 'rw', default => $ENV{AWS_SECRET_ACCESS_KEY} );
has 's3_bucket_name' =>         ( is => 'rw', default => $ENV{S3_BUCKET_NAME} );

has 's3' =>         ( is => 'ro', builder => '_build_s3', lazy => 1 );
has 'ua' =>         ( is => 'ro', builder => '_build_ua', lazy => 1 );
has 'mimetypes' =>  ( is => 'ro', default => sub { MIME::Types->new } );

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

sub store {
    my ( $self, $src, $name, $metadata, $properties ) = @_;
    my $bucket = $self->s3->bucket( $self->s3_bucket_name )
        or X->throw( error => $self->s3->err . ": " . $self->s3->errstr );

    my $head = $bucket->head_key( $name );
    if ( $head and $head->{'x-amz-meta-src-uri'} eq $src->as_string ) {
        my $img_head = $self->ua->head( $src );
        X->throw( error => $img_head->status_line ) if $img_head->is_error;
        if (
            $head->{'x-amz-meta-src-last-modified'} and $img_head->header('Last-Modified') and
            $img_head->header('Last-Modified') eq $head->{'x-amz-meta-src-last-modified'}
            or
            $head->{'x-amz-meta-src-etag'} and $img_head->header('ETag') and
            $img_head->header('ETag') eq $head->{'x-amz-meta-src-etag'}
        ) {
            print STDERR "STORE NOT MODIFIED\n";
            return 'http://'.$bucket->bucket.'.s3.amazonaws.com/'.$name;
        }
    }

    my $img_src = $self->ua->get( $src );
    X->throw( error => $img_src->status_line ) if $img_src->is_error;

    my $img_mime = $self->mimetypes->type( $img_src->header('Content-Type') );
    my $img = Imager->new(
        data => $img_src->content,
        ( $img_mime ? (type => $img_mime->subType) : () ),
    ) || X->throw( error => Imager->errstr );

    my ($width,$height,$scale,$type,$pixelratio,$bg,$align) = (
        $properties->{width}, $properties->{height},
        $properties->{scale}, $properties->{type},
        $properties->{pixelratio}, $properties->{bg},
        $properties->{align},
    ) if $properties;

    if ( defined $pixelratio and $pixelratio > 0 and $pixelratio <= 4 ) {
        $width *= $pixelratio if $width;
        $height *= $pixelratio if $height;
    }

    my $scaled = $img->scale(
        ( $width  ? ( xpixels => $width  )  : () ),
        ( $height ? ( ypixels => $height ) : () ),
        ( $scale  ? ( type    =>
            ( $scale eq 'crop' ? 'max' :
              $scale eq 'fill' ? 'min' : $scale )
        ) : () ),
    ) || X->throw( error => $img->errstr );

    my $cropped;
    if ( not defined $scale or $scale eq 'crop' ) {
        $cropped = $scaled->crop( width => $width, height => $height );
        X->throw( error => $scaled->errstr ) unless $cropped;
    } elsif ( $scale eq 'fill' ) {
        my $background = Imager->new(xsize=>$width,ysize=>$height,channels=>4);
        my $bg_color = Imager::Color->new($bg) if defined $bg;
        if ( defined $bg_color ) {
            $background->box(filled=>1,color=>$bg_color)
        }
        $background->compose(src => $scaled) || X->throw( error => $background->errstr );
        $background->settag(name => 'i_background', value => 'color(255,255,255)');
        $cropped = $background;
    } else {
        $cropped = $scaled;
    }

    my $img_out;
    my $img_out_mime = defined $type && $self->mimetypes->type( "image/$type" ) || $img_mime;
    $cropped->write(
        data => \$img_out,
        type => $img_out_mime->subType,
        jpeg_progressive => 1,
        png_interlace => 1,
        jpegquality=>90,
    ) || X->throw( error => $cropped->errstr );

    my $response = $bucket->add_key( $name, $img_out, {
        content_type => $img_out_mime->type,
        acl_short => 'public-read',
        'x-amz-meta-src-uri' => $src->as_string,
        'x-amz-meta-src-etag' => scalar $img_src->header('ETag'),
        'x-amz-meta-src-date' => scalar $img_src->header('Date'),
        'x-amz-meta-src-last-modified' => scalar $img_src->header('Last-Modified'),
        %{ $metadata || {} },
    }) || X->throw( error => $self->s3->err . ": " . $self->s3->errstr );

    return 'http://'.$bucket->bucket.'.s3.amazonaws.com/'.$name;
}

1;

