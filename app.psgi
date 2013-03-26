use Plack::Builder;

$ENV{MOJO_MODE} = $ENV{PLACK_ENV} eq 'development' ? 'development' : 'production';

builder {
    enable 'ConditionalGET';
    enable 'Static', path => '/', pass_through => 1;
    require 'scaler.pl';
};
