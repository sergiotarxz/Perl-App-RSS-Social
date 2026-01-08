package RSS::Social::Messages;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;
use RSS::Social::DB::Converter::UTF8;
use UUID qw/uuid4/;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'messages';

field id => ( is => 'ro', pk => 1, search => 1 );
field uuid            => ( is => 'rw', search   => 1, required => 1 );
field id_user_creator => (
    is       => 'ro',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::User id authors messages/]
);
field id_topic => (
    is       => 'ro',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::Topic id topics messages/]
);
field text => ( is => 'rw', required => 1, converter => RSS::Social::DB::Converter::UTF8->new);
field image_url => ( is => 'rw', search => 1 );
field upvotes => ( is => 'rw', search => 1 );
field downvotes => ( is => 'rw', search => 1 );
field created => ( is => 'rw', search => 1 );
field last_updated_votes => ( is => 'rw', search => 1 );

fix;
1;
