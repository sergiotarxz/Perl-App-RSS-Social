package RSS::Social;

use v5.42.0;
use strict;
use warnings;

use Mojo::Base 'Mojolicious';

sub startup {
	my ($self) = @_;
	my $r = $self->routes;
	$r->get('/')->to('Root#index');
	$r->get('/rs/:slug')->to('Topic#visit');
}

sub new {
	my $class = shift;
	my @args = @_;
	my $self = $class->SUPER::new(@_);
	$self->config($self->plugin('NotYAMLConfig'));
	return $self;
}
1;
