package RSS::Social::Controller::Log;

use v5.42.0;
use strict;
use warnings;

sub import {
	my (@log_route) = @_;
	my $caller = caller;
	for my $route (@log_route) {
		no strict 'refs';
		no warnings 'redefine';
		my $sub_name = "${caller}::${route}";
		my $sub = \&{"${caller}::${route}"};
		*{$sub_name} = sub {
			my ($self) = @_;
			$self->log->info("Controller (${caller}) route (${route}) url_for (@{[$self->url_for]})");
			$sub->(@_);
		}

	}
}
