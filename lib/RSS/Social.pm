package RSS::Social;

use v5.42.0;
use strict;
use warnings;

use Mojo::Base 'Mojolicious';

sub startup {
    my ($self)      = @_;
    my $main_routes = $self->routes;
    my $r           = $main_routes->under(
        '/',
        sub {
            my $c = shift;
        }
    );
    $r->get('/')->to('Root#index');
    $r->get('/rs/:slug')->to('Topic#visit');
    $r->get('/persist-user')->to('User#persist');
    $r->get('/rss/:uuid/:secret')->to('RSS#private_feed');
    $r->get('/fast-login/:uuid/:secret')->to('User#fast_login');
    my $ar = $r->under(
        '/private',
        sub {
            my $c = shift;
            if ( !$c->user ) {
                $c->reply->not_found;
                return undef;
            }
            return 1;
        }
    );
    $ar->get('/user/profile')->to('User#get_profile');
    $ar->post('/user/username', sub {
	    my $c = shift;
	    my $username = $c->param('username');
	    my $user = $c->user;
	    my $return = '/private/user/profile';
	    if (!$user) {
		    return $c->redirect_to($return);
	    }
	    if ($username !~ /^[a-zA-Z0-9 _.]{5,}$/) {
		    return $c->redirect_to($return);
	    }
	    $user->user_name($username);
	    RSS::Social::User->update($user, 'user_name');
	    return $c->redirect_to($return);
    });
    $ar->post('/user/name', sub {
	    my $c = shift;
	    my $name = $c->param('name');
	    my $user = $c->user;
	    my $return = '/private/user/profile';
	    if (!$user) {
		    return $c->redirect_to($return);
	    }
	    if ($name !~ /^[a-zA-Z0-9 _.]{3,}$/) {
		    return $c->redirect_to($return);
	    }
	    $user->name($name);
	    RSS::Social::User->update($user, 'name');
	    return $c->redirect_to($return);
    });
    $ar->post('/user/bio', sub {
	    my $c = shift;
	    my $bio = $c->param('bio');
	    my $user = $c->user;
	    my $return = '/private/user/profile';
	    if (!$user) {
		    return $c->redirect_to($return);
	    }
	    if ($bio !~ /^[a-zA-Z0-9 _.]{3,}$/) {
		    return $c->redirect_to($return);
	    }
	    $user->bio($bio);
	    RSS::Social::User->update($user, 'bio');
	    return $c->redirect_to($return);
    });
}

sub new {
    my $class = shift;
    my @args  = @_;
    my $self  = $class->SUPER::new(@_);
    $self->config( $self->plugin('NotYAMLConfig') );
    $self->helper(
        base_url => sub {
            return $self->config->{base_url};
        }
    );
    $self->helper(
        user => sub {
            my $c            = shift;
            my $user_session = $c->user_session;
            return if !$user_session;
            my ($user) = @{ $user_session->users };
            return $user if $user;
            return;
        }
    );
    $self->helper(
        user_session => sub {
            require RSS::Social::UserSession;
            my $c      = shift;
            my $cookie = $c->cookie('auth');
            return if !$cookie;
            my $user_session =
              RSS::Social::UserSession->recover_auth( split '/', "$cookie" );
            return $user_session if defined $user_session;
            return;
        }
    );
    return $self;
}
1;
