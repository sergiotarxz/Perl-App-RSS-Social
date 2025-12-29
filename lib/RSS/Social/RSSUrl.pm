package RSS::Social::RSSUrl;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
RSS::Social::DB
use UUID qw/uuid4/;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'rss_urls';

field id => ( is => 'ro', pk => 1, search => 1 );
field id_user => (
    is       => 'ro',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::User id owners rss_urls/]
);
field uuid            => ( is => 'rw', search   => 1, required => 1 );
field bcrypted_secret => ( is => 'rw', required => 1 );
field name            => ( is => 'rw', required => 1, search => 1 );
field description     => ( is => 'rw' );

fix;
1;
