use Plack::Builder;
use Plack::Middleware::Header;

$ENV{MOJO_MODE} = $ENV{PLACK_ENV} eq 'development' ? 'development' : 'production';

builder {
    enable 'ConditionalGET';
    enable 'Static', path => '/', pass_through => 1;
    enable 'Header', set => ['Access-Control-Allow-Origin' => '*'];
    require 'scaler.pl';
};
