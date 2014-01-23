package FranticCom::Scaler::WebApp::Controller::Demo;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use FranticCom::Scaler;

BEGIN { extends 'Catalyst::Controller' }

sub index : Path Args(0) Method('GET') {
    my ( $self, $c ) = @_;
    $c->stash->{scaler} = $c->forward('/get_config',['demo']);
    $c->stash->{scaler}->{image_host} = $c->req->param('image_host') if $c->req->param('image_host');
}

__PACKAGE__->meta->make_immutable;

1;
