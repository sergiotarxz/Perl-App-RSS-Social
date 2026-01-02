package RSS::Social::RSSItem;

use v5.42.0;
use strict;
use warnings;

use Moo;
use DateTime;

has title => (is => 'ro', required => 1);
has link => (is => 'ro', required => 1);
has description => (is => 'ro', required => 1);
has guid => (is => 'ro', default => sub { $_[0]->link });
# Probably bad idea to default datetime here.
has pub_date => (is => 'ro', default => sub { DateTime->now });
1;
