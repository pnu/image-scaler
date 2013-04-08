use strict;
use warnings;
use lib 'lib';
use Plack::Builder;
use Plack::Middleware::Header;
use FranticCom::Scaler;

$ENV{MOJO_MODE} = $ENV{PLACK_ENV} eq 'development' ? 'development' : 'production';

my $app = FranticCom::Scaler->new->start;

builder {
    enable 'ConditionalGET';
    enable 'Static', path => '/', pass_through => 1;
    enable 'Header', set => ['Access-Control-Allow-Origin' => '*'];
    $app;
};
