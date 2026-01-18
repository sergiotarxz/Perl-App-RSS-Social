#!/usr/bin/env perl
use strict;
use warnings;

use Mojo::File qw(curfile);
use lib curfile->dirname->sibling('lib')->to_string;
use Mojolicious::Commands;
use RSS::Social;

# Start command line interface for application
my $commands = Mojolicious::Commands->new;
my @args = @{RSS::Social->new->config->{args} // []};
$commands->start_app('RSS::Social' => 'daemon', @args);
