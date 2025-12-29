package RSS::Social::Admin;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;

sub dbh {
	return RSS::Social::DB->connect;
}

table 'admins';

field id => (is => 'ro', pk => 1, search => 1);
field uuid => (is => 'ro', required => 1, search => 1);

fix;
1;
