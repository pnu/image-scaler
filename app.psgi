use strict;
use warnings;
use lib 'lib';
use Plack::Builder;
use Plack::Middleware::Header;
use FranticCom::Scaler;

my $app = FranticCom::Scaler->psgi_app;
my $root = FranticCom::Scaler->path_to('root');

builder {
    enable 'ReverseProxy';
    enable 'ConditionalGET';
    enable 'Static', path => qr{^/(assets/|static/|favicon.ico)}, root => $root;
    enable 'Header', set => ['Access-Control-Allow-Origin' => '*'];
    $app;
};
