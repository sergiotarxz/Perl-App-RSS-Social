package RSS::Social::Controller::RSSUrl;

use v5.42.0;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

sub update_name {
    my $c = shift;
    my $user = $c->user;
    my $uuid = $c->param('uuid');
    my $name = $c->param('name');
    my ($rss_url) = @{RSS::Social::RSSUrl->search(uuid => $uuid, id_user => $user->id)};
    if (!defined $rss_url) {
        # TODO: A tu casa, a ver pocoyo
        return $c->redirect_to('/private/rss-url');
    }
    $rss_url->name($name);
    RSS::Social::RSSUrl->update($rss_url, qw/name/);
    return $c->redirect_to('/private/rss-url');
}

sub update_description {
    my $c = shift;
    my $user = $c->user;
    my $uuid = $c->param('uuid');
    my $description = $c->param('description');
    my ($rss_url) = @{RSS::Social::RSSUrl->search(uuid => $uuid, id_user => $user->id)};
    if (!defined $rss_url) {
        # TODO: A tu casa, a ver pocoyo
        return $c->redirect_to('/private/rss-url');
    }
    $rss_url->description($description);
    RSS::Social::RSSUrl->update($rss_url, qw/description/);
    return $c->redirect_to('/private/rss-url');
}
1;
