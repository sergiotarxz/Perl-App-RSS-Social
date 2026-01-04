package RSS::Social::RSSUrlSubscription;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;
use RSS::Social::DB::Converter::DateTime;
use UUID qw/uuid4/;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'rss_url_subscriptions';

field id   => ( is => 'ro', pk     => 1, search   => 1 );
field uuid => ( is => 'rw', search => 1, required => 1 );
field id_topic => (
    is       => 'ro',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::Topic id topics subscriptions/]
);
field id_rss_url => (
    is       => 'ro',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::RSSUrl id rss_urls subscriptions/]
);
field last_fetch => (
    is        => 'rw',
    search    => 1,
    converter => RSS::Social::DB::Converter::DateTime->new,
);

fix;
1;
