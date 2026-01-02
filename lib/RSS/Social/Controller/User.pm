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
    RSS::Social::UserLoginUrl->update($user_login_url, 'used');
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

RSS::Social::Controller::Log->import(qw/persist/);
1;
