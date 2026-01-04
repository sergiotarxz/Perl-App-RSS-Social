package RSS::Social::Controller::Root;

use v5.42.0;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use RSS::Social::Topic;
use RSS::Social::Controller::Log;

sub index {
	my ($self)     = @_;
	my @topics = @{RSS::Social::Topic->free_search(
		-limit => 10,
		-order_by => 'created DESC',
	)};
	$self->render(topics => \@topics);
}

RSS::Social::Controller::Log->import(qw/index/);
1;
