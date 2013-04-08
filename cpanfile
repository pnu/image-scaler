## Requirements from Makefile.PL (as defined in Makefile.PL)
##
requires 'Catalyst::Runtime', '5.90015';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General';

on 'test' => sub {
    requires 'Test::More' => '0.88';
};

## Application dependencies
##
requires 'Catalyst::View::Xslate';
requires 'Plack::Builder';
requires 'Digest::SHA';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Data::Dumper';
requires 'Net::Amazon::S3';
requires 'Exception::Class';
requires 'Imager';
requires 'LWP::UserAgent';
requires 'Try::Tiny';
requires 'Plack::Middleware::Header';
