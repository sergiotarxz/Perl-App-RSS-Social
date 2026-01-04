package RSS::Social::RSSUrl;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;
use UUID qw/uuid4/;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'rss_urls';

field id => ( is => 'ro', pk => 1, search => 1 );
field id_user => (
    is       => 'ro',
    search   => 1,
    required => 1,
    fk       => [qw/RSS::Social::User id owners rss_urls/]
);
field uuid            => ( is => 'rw', search   => 1, required => 1 );
field bcrypted_secret => ( is => 'rw', required => 1 );
field name            => ( is => 'rw', required => 1, search => 1 );
field description     => ( is => 'rw' );

fix;

instance_sub _update_last_fetch => sub {
    my $self = shift;
    for my $rss_url_subscription (
        @{ RSS::Social::RSSUrlSubscription->free_search(
                -join =>
                  [qw/rss_urls.id=rss_url_subscriptions.id_rss_url rss_urls/],
                -where => {
                    'rss_urls.id' => $self->id,
                }
            )
        }
      )
    {
        $rss_url_subscription->last_fetch( DateTime->now );
        RSS::Social::RSSUrlSubscription->update( $rss_url_subscription,
            qw/last_fetch/ );
    }
};

instance_sub _get_messages_raw => sub {
    my $self = shift;
    return RSS::Social::Messages->free_search(
        -join => [
            qw/topics.id=messages.id_topic topics
              rss_url_subscriptions.id_topic=topics.id rss_url_subscriptions
              rss_urls.id=rss_url_subscriptions.id_rss_url rss_urls/
        ],
        -where => {
            'rss_urls.id'      => $self->id,
            'messages.created' => {
                '>',
                \[
'COALESCE(rss_url_subscriptions.last_fetch, now() - ?::interval)',
                    '3 days'
                ]
            }
        },
        -limit => 20,
    );
};

instance_sub _get_messages => sub {
    my $self = shift;
    my @items;
    for my $message ( @{ $self->_get_messages_raw } ) {
        my ($topic) = @{ $message->topics };
        push @items,
          RSS::Social::RSSItem->new(
            title => 'Message in topic '
              . $topic->name . ': '
              . substr( $message->text, 0, 20 ),
            description => $message->text,
            link        => RSS::Social->new->config->{base_url} . '/rs/'
              . $topic->slug
              . '/message/'
              . $message->uuid,
          );
    }
    return @items;
};

instance_sub rss_items => sub {
    my $self = shift;
    $self->_update_last_fetch;
    return $self->_get_messages;
};

sub recover_auth {
    my $self = shift;
    my ( $uuid, $secret ) = @_;
    my ($rss_url) = @{ $self->search( uuid => $uuid ) };
    return if !defined $rss_url;
    if (
        !RSS::Social::UserSecret->new->check(
            $secret, $rss_url->bcrypted_secret
        )
      )
    {
        return;
    }
    return $rss_url;
}
1;
