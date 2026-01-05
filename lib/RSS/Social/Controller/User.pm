package RSS::Social::Controller::User;

use v5.42.0;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use RSS::Social::Topic;
use RSS::Social::Messages;
use RSS::Social::User;
use RSS::Social::Controller::Log;
use RSS::Social::UserSecret;
use RSS::Social::RSSUrl;
use RSS::Social::UserLoginUrl;
use RSS::Social::UserSession;
use RSS::Social::RSSUrlSubscription;
use UUID qw/uuid4/;

sub unsubscribe {
	my $c = shift;
	my $user = $c->user;
	my $uuid = $c->param('subscription');
	my ($subscription) = @{RSS::Social::RSSUrlSubscription->free_search(
		-join => [qw/rss_url_subscriptions.id_rss_url=rss_urls.id rss_urls/],
		-where => {
			'rss_urls.id_user' => $user->id,
			'rss_url_subscriptions.uuid' => $uuid,
		}
	)};
	return $c->redirect_to('/private/rss-url') if !$subscription;
	RSS::Social::RSSUrlSubscription->delete($subscription);
	return $c->redirect_to('/private/rss-url');
}

sub get_rss_urls {
    my $c                    = shift;
    my $user                 = $c->user;
    my @rss_urls             = @{ $user->rss_urls };
    my %url_to_subscriptions = map {
        my $rss_url = $_;
        {
            $rss_url->uuid => {
                rss_url       => $rss_url,
                subscriptions => $rss_url->subscriptions,
            }
        };
    } @rss_urls;
    return $c->render(
        template             => 'user/get_rss_url',
        url_to_subscriptions => \%url_to_subscriptions
    );
}

sub subscribe {
    my $c            = shift;
    my $topic_uuid   = $c->param('topic');
    my $rss_url_uuid = $c->param('rss_url');
    my ($topic)      = @{ RSS::Social::Topic->search( uuid => $topic_uuid ) };
    if ( !$topic ) {
        return $c->redirect_to('/');
    }
    my ($rss_url) = @{ RSS::Social::RSSUrl->search( uuid => $rss_url_uuid ) };
    if ( !$rss_url ) {
        return $c->redirect_to('/');
    }
    my $uuid                 = uuid4();
    my $rss_url_subscription = RSS::Social::RSSUrlSubscription::Instance->new(
        uuid       => $uuid,
        id_topic   => $topic->id,
        id_rss_url => $rss_url->id,
    );
    RSS::Social::RSSUrlSubscription->insert($rss_url_subscription);
    return $c->redirect_to( '/rs/' . $topic->slug );
}

sub delete_message {
    my $c            = shift;
    my $message_uuid = $c->param('uuid');
    my ($message) = @{ RSS::Social::Messages->search( uuid => $message_uuid ) };
    if ( !defined $message ) {
        return $c->redirect_to('/');
    }
    my ($message_user) = @{ $message->authors };
    if ( !defined $message_user || $c->user->uuid ne $message_user->uuid ) {
        return $c->redirect_to('/');
    }
    my ($topic) = @{ $message->topics };
    RSS::Social::Messages->delete($message);
    return $c->redirect_to( '/rs/' . $topic->slug );
}

sub public_profile {
    my $self            = shift;
    my $user_identifier = $self->param('user_identifier');
    my ($user)          = @{ RSS::Social::User->search(
            uuid => $user_identifier,
        )
    };
    if ( defined $user ) {
        return $self->render( user => $user );
    }
    ($user) = @{ RSS::Social::User->search(
            user_name => $user_identifier,
        )
    };
    if ( defined $user ) {
        return $self->render( user => $user );
    }
    return $self->reply->not_found;

}

sub persist {
    my ($self)  = @_;
    my $slug    = $self->param('slug');
    my ($topic) = @{ RSS::Social::Topic->search(
            slug => $slug,
        )
    };
    my $uuid = uuid4();
    my $user = RSS::Social::User::Instance->new( uuid => $uuid, );
    RSS::Social::User->insert($user);
    ($user) = @{ RSS::Social::User->search( uuid => $uuid, ) };
    my $rss_url_uuid = uuid4();
    my ( $secret, $bcrypted ) = RSS::Social::UserSecret->new->generate_random;
    my $rss_url = RSS::Social::RSSUrl::Instance->new(
        id_user         => $user->id,
        uuid            => $rss_url_uuid,
        bcrypted_secret => $bcrypted,
        name            => 'RSS::Social - First RSS feed',
        description     => 'This was your first generated login RSS URL',
    );
    RSS::Social::RSSUrl->insert($rss_url);

    $self->render( secret => $secret, uuid => $rss_url_uuid );
}

sub get_profile {
    my $c     = shift;
    my $error = $c->param('error');
    return $c->render( error => $error );
}

sub fast_login {
    my $self   = shift;
    my $uuid   = $self->param('uuid');
    my $secret = $self->param('secret');
    my $user_login_url =
      RSS::Social::UserLoginUrl->recover_auth( $uuid, $secret );
    if ( !$user_login_url ) {
        return $self->reply->not_found;
    }
    $user_login_url->used(1);
    RSS::Social::UserLoginUrl->update( $user_login_url, 'used' );
    $user_login_url = $user_login_url->fetch_again;
    my ($user) = @{ $user_login_url->users };
    return $self->reply->not_found if !$user;
    my ( $session, $session_secret ) =
      RSS::Social::UserSession->generate_for_user($user);
    $self->cookie(
        auth => $session->uuid . '/' . $session_secret,
        { expires => time + ( 3600 * 24 ), path => '/' }
    );
    $self->redirect_to( $self->config->{base_url} );
}

sub update_username {
    my $c        = shift;
    my $username = $c->param('username');
    my $user     = $c->user;
    my $return   = '/private/user/profile';
    if ( !$user ) {
        return $c->redirect_to($return);
    }
    if ( $username !~ /^[a-zA-Z0-9 _.]{5,}$/ ) {
        return $c->redirect_to($return);
    }
    $user->user_name($username);
    eval { RSS::Social::User->update( $user, 'user_name' ); };
    if ($@) {
        return $c->redirect_to("$return?error=The%20username%20is%20taken");
    }
    return $c->redirect_to($return);
}

sub update_name {
    my $c      = shift;
    my $name   = $c->param('name');
    my $user   = $c->user;
    my $return = '/private/user/profile';
    if ( !$user ) {
        return $c->redirect_to($return);
    }
    if ( $name !~ /^[a-zA-Z0-9 _.]{3,}$/ ) {
        return $c->redirect_to($return);
    }
    $user->name($name);
    RSS::Social::User->update( $user, 'name' );
    return $c->redirect_to($return);
}

sub update_bio {
    my $c      = shift;
    my $bio    = $c->param('bio');
    my $user   = $c->user;
    my $return = '/private/user/profile';
    if ( !$user ) {
        return $c->redirect_to($return);
    }
    $user->bio($bio);
    RSS::Social::User->update( $user, 'bio' );
    return $c->redirect_to($return);
}

RSS::Social::Controller::Log->import(
    qw/persist fast_login update_username update_name update_bio/);
1;
