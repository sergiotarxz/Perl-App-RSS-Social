package RSS::Social::UserLoginUrl;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::User;
use RSS::Social::UserSecret;
use UUID qw/uuid4/;

require RSS::Social::UserPermission;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'users_login_urls';

field id => ( is => 'ro', pk => 1, search => 1 );
field id_user => (
    is       => 'ro',
    fk       => [qw/RSS::Social::User id users login_urls/],
    search   => 1,
    required => 1
);
field uuid => (
    is       => 'ro',
    search   => 1,
    required => 1
);

field bcrypted_secret => (
    is       => 'ro',
    required => 1
);

field used => (
    is     => 'rw',
    search => 1,
);

field created => (
    is     => 'ro',
    search => 1,
);

fix;

sub generate_for_user {
    my ( $self, $user )       = @_;
    my ( $secret, $bcrypted ) = RSS::Social::UserSecret->new->generate_random;
    my $uuid           = uuid4();
    my $user_login_url = RSS::Social::UserLoginUrl::Instance->new(
        uuid            => $uuid,
        bcrypted_secret => $bcrypted,
        id_user         => $user->id,
    );
    RSS::Social::UserLoginUrl->insert($user_login_url);
    ($user_login_url) = @{ RSS::Social::UserLoginUrl->search( uuid => $uuid ) };
    return ( $user_login_url, $secret );
}

sub recover_auth {
	my $self = shift;
	my ($uuid, $secret) = @_;
        my ($user_login_url) = @{
            $self->search(
                uuid    => $uuid,
                used    => 0,
                created => {'>' => \['now() - ?::interval', '10 minutes']},
            )
        };
	return if !$user_login_url;
	if (!RSS::Social::UserSecret->new->check($secret, $user_login_url->bcrypted_secret)) {
		return;
	}
	return $user_login_url;
}
1;
