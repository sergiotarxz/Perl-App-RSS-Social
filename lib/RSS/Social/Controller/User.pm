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
use UUID qw/uuid4/;

sub delete_message {
    my $c            = shift;
    my $message_uuid = $c->param('uuid');
    my ($message) = @{ RSS::Social::Messages->search( uuid => $message_uuid ) };
    if ( !defined $message ) {
        say 'hola';
        return $c->redirect_to('/');
    }
    my ($message_user) = @{ $message->authors };
    if ( !defined $message_user || $c->user->uuid ne $message_user->uuid ) {
        say 'hola';
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
