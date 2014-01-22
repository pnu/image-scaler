package FranticCom::Scaler::WebApp::Controller::Root;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use FranticCom::Scaler;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

has 'scaler' => ( is => 'ro', default => sub { FranticCom::Scaler->new } );

sub get_config : Private {
    my ( $self, $c ) = @_;
    return {
        image_host => $self->scaler->image_host,
        max_retries => $self->scaler->max_retries,
        retry_delay => $self->scaler->retry_delay,
        trigger_url => $c->uri_for_action('/index')
    };
}

sub index : Path Args(0) Method('POST') {
    my ( $self, $c ) = @_;
    $c->model('Worker')->scaler($c->req->params);
    $c->res->status(204);
}

sub default : Path {
    my ( $self, $c ) = @_;
    $c->res->status(404);
    $c->res->body('');
}

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
}

__PACKAGE__->meta->make_immutable;

1;
