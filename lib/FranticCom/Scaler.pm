package FranticCom::Scaler;
use Moose;
use namespace::autoclean;
use Catalyst::Runtime 5.80;
use Catalyst qw/
    ConfigLoader
    Unicode::Encoding
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->setup();

1;
