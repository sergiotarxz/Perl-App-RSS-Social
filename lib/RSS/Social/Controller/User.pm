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
    return shift->render;
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
    RSS::Social::User->update( $user, 'user_name' );
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
