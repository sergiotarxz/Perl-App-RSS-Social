package RSS::Social::UserRom;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;
use RSS::Social::User;
use UUID qw/uuid4/;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'user_roms';

field id => ( is => 'ro', pk => 1, search => 1 );
field name => (is => 'ro', search => 1, required => 1);
field id_user => (
    is       => 'ro',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::User id users roms/]
);
field uuid          => ( is => 'ro', search   => 1, required => 1 );
field rom_sha256sum => ( is => 'ro', required => 1, search   => 1 );

field rom  => ( is => 'ro', required => 1 );
field save => ( is => 'rw' );
field creation_time => (
    is        => 'ro',
    search    => 1,
    converter => RSS::Social::DB::Converter::DateTime->new,
);

field last_save => (
    is        => 'rw',
    search    => 1,
    converter => RSS::Social::DB::Converter::DateTime->new,
);
fix;
1;
