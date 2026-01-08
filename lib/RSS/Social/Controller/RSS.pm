package RSS::Social::Controller::RSS;

use v5.42.0;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

sub private_feed {
	my $self = shift;
	my $uuid = $self->param('uuid');
	my $secret = $self->param('secret');
	my $rss_url = RSS::Social::RSSUrl->recover_auth($uuid, $secret);
	if (!$rss_url) {
		return $self->reply->not_found;
	}
	my ($user) = @{$rss_url->owners};
	if (!$user) {
		return $self->reply->not_found;
	}
	my @items = ($rss_url->rss_items, $user->rss_items);
	$self->res->headers->content_type('application/xml');
	$self->render(format => 'xml', rss_url => $rss_url, items => \@items);
}
1;
