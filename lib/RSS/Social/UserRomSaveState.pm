package RSS::Social::UserRomSaveState;

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

table 'user_rom_save_states';

field id => ( is => 'ro', pk => 1, search => 1 );
field uuid => (is => 'ro', search => 1, required => 1);
field id_rom => (
    is       => 'ro',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::UserRom id roms save_states/]
);
field save_state  => ( is => 'ro', required => 1 );
field created => (
    is        => 'ro',
    search    => 1,
    converter => RSS::Social::DB::Converter::DateTime->new,
);
fix;
1;
