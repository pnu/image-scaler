use Mojolicious::Lite;
use Digest::SHA qw(sha256_hex);
use lib 'lib';
use FranticCom::Scaler::AmazonS3;
use Try::Tiny;

plugin 'xslate_renderer';
plugin 'Config' => { file => 'scaler.conf' };

my $s3 = FranticCom::Scaler::AmazonS3->new;

get '/demo' => sub {
    my $self = shift;
    $self->render(template=>'demo', format=>'html', handler=>'tx');
};

get '/scaler.js' => sub {
    my $self = shift;
    $self->stash->{timeout} = $self->config->{timeout};
    $self->stash->{bucketurl} = 'http://s3-eu-west-1.amazonaws.com/'.
        $s3->bucket->bucket.'/';
    $self->render(template=>'scaler', format=>'js', handler=>'tx');
};

get '/trigger' => sub {
    my $self = shift;
    try { 
        my $args = {
            width => scalar $self->param('width'),
            height => scalar $self->param('height'),
            scale => scalar $self->param('data[scale]'),
            src => scalar $self->param('data[src]'),
        };
        my $res = $s3->store( $args, $self );
        $self->res->headers->header( 'X-Frantic-Scaler' => $res );
        $self->render( text => '', format=>'txt', status => 204 );
    } catch {
        die $_ if app->mode eq 'development';
        $self->render( text => '', format=>'txt', status => 403 );
    };
};

app->start;
