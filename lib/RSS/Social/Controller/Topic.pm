package RSS::Social::Controller::Topic;

use v5.42.0;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use RSS::Social::Topic;
use RSS::Social::Messages;
use RSS::Social::User;
use RSS::Social::Controller::Log;

sub visit {
	my ($self)     = @_;
	my $slug = $self->param('slug');
	my ($topic) = @{RSS::Social::Topic->search(
		slug => $slug,
	)};
	my @messages = @{RSS::Social::Messages->free_search(
		-where => {
			'messages.id_topic' => $topic->id,
		},
		-limit => 30,
		-order_by => 'messages.created DESC',
	)};
	$self->render(topic => $topic, messages => \@messages);
}

RSS::Social::Controller::Log->import(qw/visit/);
1;
