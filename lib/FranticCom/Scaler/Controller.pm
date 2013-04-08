package FranticCom::Scaler::Controller;

use Mojo::Base 'Mojolicious::Controller';
use Digest::SHA qw(sha256_hex);
use FranticCom::Scaler::AmazonS3;
use Try::Tiny;

my $s3 = FranticCom::Scaler::AmazonS3->new;

my $image_s3_url = sub {
    my ( $data ) = @_;
    my $src = $data->{src};
    my $width = $data->{width} || '_';
    my $height = $data->{height} || '_';
    my $pixelratio = $data->{pixelratio} || '_';
    my $scale = $data->{scale} || '_';
    my $type = $data->{type} || '_';
    my $salt = $data->{salt} || '_';
    my $key = $src.$width.$height.$pixelratio.$scale.$type.$salt;
    my $hash = sha256_hex( $key );
    print STDERR "HASH $src ($width x $height x $pixelratio x $scale x $type x $salt) -> $hash\n";
    return $hash;
};

my $image_s3_url_js = q{ function(data) {
        var src = data.src;
        var width = data.width || '_';
        var height = data.height || '_';
        var pixelratio = data.pixelratio || '_';
        var scale = data.scale || '_';
        var type = data.type || '_';
        var salt = data.salt || '_';
        var key = src+width+height+pixelratio+scale+type+salt;
        var hash = $.sha256(key);
        console.log("HASH "+src+" ("+width+" x "+height+" x "+pixelratio+" x "+scale+" x "+type+" x "+salt+") -> "+hash);
        return hash;
    }};

sub demo {
    my $self = shift;
    $self->render(template=>'demo', format=>'html', handler=>'tx');
}

sub scalerjs {
    my $self = shift;
    $self->stash->{image_s3_url_code} = $image_s3_url_js;
    $self->stash->{timeout} = $self->config->{timeout};
    $self->stash->{bucketname} = $s3->s3_bucket_name;
    $self->res->headers->header( 'Cache-Control' => 'max-age=600' );
    $self->render(template=>'scaler', format=>'js', handler=>'tx');
}

sub trigger {
    my $self = shift;
    try {
        my $properties = $self->req->params->to_hash;
        my $src = $properties->{src};
        my $bucket = $properties->{bucket} || undef;
        my $name = $image_s3_url->($properties);
        my $metadata = {
            ##'x-amz-meta-client-remote-address' => $self->tx->remote_address,
            'x-amz-meta-client-user-agent' => $self->req->headers->user_agent,
        };
        my $res = $s3->store( $src, $bucket, $name, $metadata, $properties );
        print STDERR "TRIGGER $res\n";
        $self->res->headers->header( 'X-Frantic-Scaler-Source-URL' => $src );
        $self->res->headers->header( 'X-Frantic-Scaler-URL' => $res );
        $self->render( text => '', format=>'txt', status => 204 );
    } catch {
        print STDERR "TRIGGER ERROR $_\n";
        die $_ if app->mode eq 'development';
        $self->render( text => '', format=>'txt', status => 403 );
    };
}

1;
