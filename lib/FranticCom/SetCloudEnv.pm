package FranticCom::SetCloudEnv;
use strict;
use warnings;
use JSON;
use URI;
use Digest::SHA qw(sha256_hex);

sub import {
    my ($self, $environment) = @_;

    $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} ||= $environment;

    ## Process dotcloud environment
    if ( open my $fh, "<", "/home/dotcloud/environment.json" ) {
        my $data = JSON::decode_json(join '', <$fh>);
        $ENV{$_} = $data->{$_} for keys %$data;
        if ( $ENV{DOTCLOUD_DB_MYSQL_URL} ) {
            $ENV{DBI_DRIVER} = 'mysql';
            $ENV{DBI_HOST}   = $ENV{DOTCLOUD_DB_MYSQL_HOST}; # non-standard
            $ENV{DBI_PORT}   = $ENV{DOTCLOUD_DB_MYSQL_PORT}; # non-standard
            $ENV{DBI_USER}   = $ENV{DOTCLOUD_DB_MYSQL_LOGIN};
            $ENV{DBI_PASS}   = $ENV{DOTCLOUD_DB_MYSQL_PASSWORD};
        }
    }

    ## Process heroku environment
    my $dburl = $ENV{DATABASE_URL};
    if ( $dburl and $dburl =~ s/^postgres:// ) {
        my $pgurl = URI->new( $dburl, 'http' );
        $ENV{PGHOST} = $pgurl->host;
        $ENV{PGPORT} = $pgurl->port;
        $ENV{PGDATABASE} = substr $pgurl->path, 1;
        ($ENV{PGUSER},$ENV{PGPASSWORD}) = split ':', $pgurl->userinfo;

        $ENV{DBI_DRIVER} = 'Pg';
        $ENV{DBI_DSN}    = 'dbi:Pg:'.$ENV{PGDATABASE}.'@'.$ENV{PGHOST}.':'.$ENV{PGPORT};
        $ENV{DBI_USER}   = $ENV{PGUSER};
        $ENV{DBI_PASS}   = $ENV{PGPASSWORD};
    }

    if ( $ENV{HEROKU_APP_NAME} && $ENV{HEROKU_API_KEY} ) {
        eval {
            require Net::Heroku;
            my $heroku = Net::Heroku->new( api_key => $ENV{HEROKU_API_KEY} );
            my @releases = $heroku->releases( name => $ENV{HEROKU_APP_NAME} );
            my $name = $releases[-1]->{name};
            my $commit = $releases[-1]->{commit};
            my $id = "$ENV{HEROKU_APP_NAME}-$name-$commit";
            print STDERR "Heroku API: release $id\n";
            $ENV{HEROKU_RELEASE_NAME} = $name;
            $ENV{HEROKU_RELEASE_ID} = $id;
        }
    }

    $ENV{RELEASE_UUID} = sha256_hex( $ENV{HEROKU_RELEASE_ID} || rand );

    my $redisurl = $ENV{REDISCLOUD_URL} || 'redis://localhost:6379/';
    if ( $redisurl and $redisurl =~ s/^redis:// ) {
        my $url = URI->new( $redisurl, 'http' );
        $ENV{REDISHOST} = $url->host;
        $ENV{REDISPORT} = $url->port;
        (undef,$ENV{REDISPASSWORD}) = split ':', $url->userinfo
            if $url->userinfo;
    }

    return 1;
}

1;
