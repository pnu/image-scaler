package FranticCom::Scaler::WebApp::Controller::Demo;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use FranticCom::Scaler;

BEGIN { extends 'Catalyst::Controller' }

sub index : Path Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{scaler} = $c->forward('/get_config');
}

__PACKAGE__->meta->make_immutable;

1;
