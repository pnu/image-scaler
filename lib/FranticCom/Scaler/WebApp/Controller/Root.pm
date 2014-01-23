package FranticCom::Scaler::WebApp::Controller::Root;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use FranticCom::Scaler;
use IO::File;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

has 'scaler' => ( is => 'ro', default => sub { FranticCom::Scaler->new } );

sub get_config : Private {
    my ( $self, $c ) = @_;
    return {
        image_host => $self->scaler->image_host,
        max_retries => $self->scaler->max_retries,
        retry_delay => $self->scaler->retry_delay,
        trigger_url => $c->uri_for_action('/index_trigger')
    };
}

sub index_trigger : Path Args(0) Method('POST') {
    my ( $self, $c ) = @_;
    $c->model('Worker')->scaler($c->req->params);
    $c->res->status(204);
}

sub index_get_js : Path Args(1) Method('GET') {
    my ( $self, $c, $version ) = @_;
    $c->detach('unsupported_version') unless ( $version && $version eq '1' );
    my $full_path = $c->path_to( 'root','assets','js','scaler.js' );
    my $fh = IO::File->new( $full_path, 'r' );
    if ( defined $fh ) {
        binmode $fh;
        $c->res->body( $fh );
        $c->res->header('Content-Type' => 'application/javascript');
    } else {
        $c->detach('not_found');
    }
}

sub default : Path {
    my ( $self, $c ) = @_;
    $c->detach('not_found');
}

sub unsupported_version : Private {
    my ( $self, $c ) = @_;
    $c->res->status(404);
    $c->res->body('unsupported version');
}

sub not_found : Private {
    my ( $self, $c ) = @_;
    $c->res->status(404);
    $c->res->body('not found');
}

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
}

__PACKAGE__->meta->make_immutable;

1;
