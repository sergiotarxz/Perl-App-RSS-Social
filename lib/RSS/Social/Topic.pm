package RSS::Social::Topic;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;
use UUID qw/uuid4/;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'topics';

field id        => ( is => 'ro', pk     => 1, search   => 1 );
field uuid      => ( is => 'ro', search => 1, required => 1 );
field slug => ( is => 'rw', search => 1, required => 1);
field name  => ( is => 'rw', search => 1, required => 1);
field description      => ( is => 'rw' );
field id_user_created_by   => ( is => 'rw', fk     => [qw/RSS::Social::User id creators created_topics/], search => 1 );

fix;
1;
