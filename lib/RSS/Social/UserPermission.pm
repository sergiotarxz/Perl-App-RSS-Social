package RSS::Social::UserPermission;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;
use UUID qw/uuid4/;

require RSS::Social::User;
require RSS::Social::Permission;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'user_permissions';

field id   => ( is => 'ro', pk     => 1, search   => 1 );
field uuid => ( is => 'ro', search => 1, required => 1 );
field id_permission => (
    is       => 'rw',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::Permission id permissions user_permissions/]
);
field id_user => (
    is       => 'rw',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::User id users user_permissions/]
);
fix;
1;
