package FranticCom::Scaler;
use Moose;
use namespace::autoclean;
use Digest::SHA qw(sha256_hex);
use Try::Tiny;
use FranticCom::Scaler::AmazonS3;

has 's3' => ( is => 'ro', default => sub { FranticCom::Scaler::AmazonS3->new } );
has 'prefix' => ( is => 'ro', default => $ENV{FRANTICCOM_SCALER_PREFIX} );
has 'host' => ( is => 'ro', default => $ENV{FRANTICCOM_SCALER_HOST} );
has 'max_retries' => ( is => 'ro', default => 10 );
has 'retry_delay' => ( is => 'ro', default => 1000 );

sub image_host {
    my ( $self ) = @_;
    my $host = $self->host ? $self->host : $self->s3->s3_bucket_name.'.s3.amazonaws.com';
    return $self->prefix ? $host.'/'.$self->prefix : $host;
}

sub image_path {
    my ( $self, $data ) = @_;
    my $src = $data->{src} || '_';
    my $width = $data->{width} || '_';
    my $height = $data->{height} || '_';
    my $pixelratio = $data->{pixelratio} || '1';
    my $scale = $data->{scale} || '_';
    my $type = $data->{type} || '_';
    my $salt = $data->{salt} || '_';
    my $key = $src.$width.$height.$pixelratio.$scale.$type.$salt;
    my $hash = sha256_hex( $key );
    return $hash;
}

sub trigger {
    my ( $self, $properties ) = @_;
    my $src = $properties->{src};
    my $id = $properties->{id};
    my $name = $self->prefix ? $self->prefix.'/' : '';
    $name .= $id ? $id.'/' : '';
    $name .= $self->image_path($properties);
    my $metadata = {
        'Cache-Control' => 'public,max-age=604800',
    };
    return $self->s3->store( $src, $name, $metadata, $properties );
}

__PACKAGE__->meta->make_immutable;

1;
