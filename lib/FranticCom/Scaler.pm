package FranticCom::Scaler;

use Mojo::Base 'Mojolicious';

sub startup {
    my $self = shift;
    $self->secret('Mojolicious rocks');
    $self->plugin('xslate_renderer');
    $self->plugin('Config');
    my $r = $self->routes;
    $r->get('demo')->to('controller#demo');
    $r->get('scaler.js')->to('controller#scalerjs');
    $r->get('trigger')->to('controller#trigger');
}

1;
