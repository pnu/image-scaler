use Mojolicious::Lite;
use Digest::SHA qw(sha256_hex);
use lib 'lib';
use FranticCom::Scaler::AmazonS3;
use Try::Tiny;

plugin 'xslate_renderer';
plugin 'Config' => { file => 'scaler.conf' };

my $s3 = FranticCom::Scaler::AmazonS3->new;

my $image_s3_url = sub {
    my ( $data ) = @_;
    my $src = $data->{src};
    my $width = $data->{width} || '_';
    my $height = $data->{height} || '_';
    my $scale = $data->{scale} || '_';
    my $key = $src.$width.$height.$scale;
    warn "HASHING $key";
    sha256_hex( $key );
};

my $image_s3_url_js = q{ function(data) {
        var src = data.src;
        var width = data.width || '_';
        var height = data.height || '_';
        var scale = data.scale || '_';
        var key = src+width+height+scale;
        console.log("HASHING ",key);
        return $.sha256(key);
    }};

get '/demo' => sub {
    my $self = shift;
    $self->render(template=>'demo', format=>'html', handler=>'tx');
};

get '/scaler.js' => sub {
    my $self = shift;
    $self->stash->{image_s3_url_code} = $image_s3_url_js;
    $self->stash->{timeout} = $self->config->{timeout};
    $self->stash->{bucketurl} = 'http://s3-eu-west-1.amazonaws.com/'.
        $s3->bucket->bucket.'/';
    $self->res->headers->header( 'Cache-Control' => 'max-age=600' );
    $self->render(template=>'scaler', format=>'js', handler=>'tx');
};

get '/trigger' => sub {
    my $self = shift;
    try {
        my $properties = $self->req->params->to_hash;
        my $src = $properties->{src};
        my $name = $image_s3_url->($properties);
        my $metadata = {
            ##'x-amz-meta-client-remote-address' => $self->tx->remote_address,
            'x-amz-meta-client-user-agent' => $self->req->headers->user_agent,
        };
        my $res = $s3->store( $src, $name, $metadata, $properties );
        $self->res->headers->header( 'X-Frantic-Scaler' => $res );
        $self->render( text => '', format=>'txt', status => 204 );
    } catch {
        die $_ if app->mode eq 'development';
        $self->render( text => '', format=>'txt', status => 403 );
    };
};

app->start;
