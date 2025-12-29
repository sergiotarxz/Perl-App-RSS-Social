package RSS::Social::Permission;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;
use UUID qw/uuid4/;

require RSS::Social::UserPermission;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'permissions';

field id          => ( is => 'ro', pk     => 1, search   => 1 );
field uuid        => ( is => 'rw', search => 1, required => 1 );
field slug        => ( is => 'rw', search => 1, required => 1 );
field name        => ( is => 'rw', search => 1 );
field description => ( is => 'rw', search => 1 );

fix;
1;
