package FranticCom::Scaler::WebApp;
use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.80;
use Catalyst qw/
    ConfigLoader
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->setup();

1;
