package RSS::Social::Controller::Rom;

use v5.42.0;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

use RSS::Social::User;
use RSS::Social::UserRom;
use Path::Tiny;
use File::pushd;
use Digest::SHA qw/sha256_hex/;
use UUID        qw/uuid4/;
use DBD::Pg qw(:pg_types);
use SQL::Abstract::More;
use RSS::Social::DB;

sub randomize {
    my $self = shift;
    $self->render( template => 'rom/randomize' );
}

sub post_randomize {
    my $self = shift;
    my $name = $self->param('name');
    if ( $name !~ /^[a-zA-Z0-9 ]{3,}$/ ) {
        return $self->redirect_to('/private/rom/randomize');
    }
    my $user                  = $self->user;
    my $uuid                  = uuid4();
    my $tmpdir                = Path::Tiny->tempdir;
    my $new_firered_directory = "$tmpdir/pokefirered";
    my $randomizer = path('Perl-Randomize-Firered/randomize.pl')->realpath;
    system 'cp', '-r', 'pokefirered', $new_firered_directory;
    my $rom;
    {
        my $pushd = pushd $new_firered_directory;
        system 'git stash';
        system 'perl', $randomizer;
        system 'make';
        $rom = path('pokefirered.gba')->slurp_raw;
    }
    if ( !defined $rom ) {
        return $self->redirect_to('/private/rom/randomize');
    }
    my $sha_rom = sha256_hex($rom);

    my $dbh = RSS::Social::DB->connect;
    my $sqla = SQL::Abstract::More->new;
    my ( $sql, @bind ) = $sqla->insert(
        -into   => 'user_roms',
        -values => {
            uuid          => $uuid,
            id_user       => $user->id,
            name          => $name,
            rom_sha256sum => $sha_rom,
            rom           => [{dbd_attrs => { pg_type => PG_BYTEA }}, $rom],
        }
    );
    my $sth = $dbh->prepare($sql);
    $sqla->bind_params($sth, @bind);
    $sth->execute;
    return $self->redirect_to( '/private/play/' . $name );
}
1;
