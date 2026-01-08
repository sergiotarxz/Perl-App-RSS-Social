package RSS::Social::Wiki;

use v5.42.0;
use strict;
use warnings;

use Wiki::JSON;
use Cpanel::JSON::XS qw/encode_json decode_json/;
use Moo;
use Time::HiRes qw/time/;
use Mojo::IOLoop;

has _write_to_server  => ( is => 'rw' );
has _read_from_server => ( is => 'rw' );
has _server_pid       => ( is => 'rw' );

{
    my $instance;
    sub singleton {
        my $class = shift;
        if (!defined $instance) {
            $instance = $class->new;
        }
        return $instance;
    }
}

{
    my %forbidden_strings;

    sub parse {
        my $self = shift;
        my $wiki = shift;
        die "Refusing to render '$wiki', rendering errored before"
          if $forbidden_strings{$wiki};
        $self->_start_server_if_needed;
        $self->_send_to_server_parse_string($wiki);
        my $out;
        eval { $out = $self->_wait_server_response_or_die; };
        if ($@) {
            $forbidden_strings{$wiki} = 1;
            die "Rendering error '$@' for '$wiki'";
        }
        return $out;
    }
}

sub _wait_server_response_or_die {
    my $self = shift;
    $self->_read_from_server->blocking(0);
    my $line;
    my $tries = 0;
    my $time = time;
    while ( !defined( $line = $self->_read_from_server->getline ) ) {
        die 'Remote process did not answer, there is a bug in Wiki::JSON'
          if scalar(time) > $time + 30_000 || !$self->_is_server_alive;
    }
    return decode_json($line);
}

sub _send_to_server_parse_string {
    my ( $self, $wiki ) = @_;
    $self->_write_to_server->say( encode_json( { wiki => $wiki } ) );
    $self->_write_to_server->flush;
}

sub _start_server {
    my ($self) = @_;
    pipe my ( $read_from_client, $write_to_server );
    pipe my ( $read_from_server, $write_to_client );
    $self->_write_to_server($write_to_server);
    $self->_read_from_server($read_from_server);
    my $parent_pid = $$;
    my $pid = fork;
    if (!$pid) {
        Mojo::IOLoop->singleton->reset({freeze => 1});
        my $wiki_json = Wiki::JSON->new;
        $read_from_client->blocking(0);
        while (1) {
            exit if !kill 0, $parent_pid;
            eval {
                my $input   = <$read_from_client>;
                if (!defined $input) {
                    return;
                }
                my $content = decode_json($input)->{wiki};
                $write_to_client->say(
                    encode_json( $wiki_json->pre_html($content) ) );
                $write_to_client->flush;
            };
            if ($@) {
                warn 'Process died because of: ' . $@ . ' restarting';
                exit 1;
            }
        }
        exit;
    }
    $self->_server_pid($pid);
    close $read_from_client;
    close $write_to_client;
}

sub _start_server_if_needed {
    my $self = shift;
    return if $self->_is_server_alive;
    $self->_start_server;
}

sub _is_server_alive {
    my $self = shift;
    return if !defined $self->_server_pid;
    return if !kill 0, $self->_server_pid;
    return 1;
}
1;
