package FranticCom::Scaler::WebApp::Model::Worker;
use namespace::autoclean;
use Moose;
use Redis;
use Data::Dumper;
use JSON qw( encode_json );

extends 'Catalyst::Model';

has 'redis' => ( is => 'ro', builder => '_redis_builder', lazy => 1 );
has 'redis_host'     => ( is => 'ro', default => $ENV{REDISHOST} );
has 'redis_port'     => ( is => 'ro', default => $ENV{REDISPORT} );
has 'redis_password' => ( is => 'ro', default => $ENV{REDISPASSWORD} );

sub _redis_builder {
    my $self = shift;
    return Redis->new(
        server   => $self->redis_host.':'.$self->redis_port,
        password => $self->redis_password,
    );
}

sub scaler {
    my ( $self, $data ) = @_;
    return unless $data;
    return $self->redis->rpush('scaler',encode_json($data));
}

__PACKAGE__->meta->make_immutable;

1;
