package FranticCom::Scaler::Controller::Root;
use Moose;
use namespace::autoclean;
use Digest::SHA qw(sha256_hex);
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

has 'outprefix' => ( is => 'rw', default => $ENV{FRANTICCOM_SCALER_PREFIX} || 'scaler/' );

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

sub demo : Local Args(0) {
    my ( $self, $c ) = @_;
}

sub scalerjs : Path('scaler.js') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{image_s3_url_code} = $image_s3_url_js;
    $c->stash->{timeout} = 10000;
    $c->stash->{bucketname} = $c->model('AmazonS3')->s3_bucket_name;
    $c->stash->{outprefix} = $self->outprefix;
    $c->res->headers->header( 'Cache-Control' => 'max-age=600' );
    $c->res->content_type('application/javascript');
}

sub trigger : Local Args(0) {
    my ( $self, $c ) = @_;
    try {
        my $properties = $c->req->params;
        my $src = $properties->{src};
        my $bucket = $properties->{bucket} || undef;
        my $name = $self->outprefix.$image_s3_url->($properties);
        my $metadata = {
            ##'x-amz-meta-client-remote-address' => $self->tx->remote_address,
            'x-amz-meta-client-user-agent' => $c->req->headers->user_agent,
        };
        my $res = $c->model('AmazonS3')->store( $src, $bucket, $name, $metadata, $properties );
        print STDERR "TRIGGER $res\n";
        $c->res->headers->header( 'X-Frantic-Scaler-Source-URL' => $src );
        $c->res->headers->header( 'X-Frantic-Scaler-URL' => $res );
        $c->res->body('');
        $c->res->status(204);
    } catch {
        print STDERR "TRIGGER ERROR $_\n";
        ##die $_ if app->mode eq 'development';
        $c->res->status(403);
    };
}

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
}

__PACKAGE__->meta->make_immutable;

1;
