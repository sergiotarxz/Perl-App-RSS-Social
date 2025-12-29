package RSS::Social::MessageVotes;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
RSS::Social::DB
use UUID qw/uuid4/;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'messages_votes';

field id => ( is => 'ro', pk => 1, search => 1 );
field uuid            => ( is => 'rw', search   => 1, required => 1 );
field id_user => (
    is       => 'ro',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::User id caster votes/]
);
field id_message => (
    is       => 'ro',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::Messages id messages votes/]
);
field is_upvote => ( is => 'rw', required => 1, search => 1 );

fix;
1;
