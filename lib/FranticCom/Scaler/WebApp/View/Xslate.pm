package FranticCom::Scaler::WebApp::View::Xslate;
use Moose;
extends 'Catalyst::View::Xslate';

has '+expose_methods' => (
    is => 'ro',
    default => sub {{
        'lc' => 'do_lc'
    }}
);

sub do_lc {
    my ( $self, $c, $text ) = @_;
    return lc $text;
}

1;
