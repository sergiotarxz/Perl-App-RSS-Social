package RSS::Social::UserSession;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;
use RSS::Social::DB::Converter::DateTime;
use UUID qw/uuid4/;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'users_sessions';

field id => ( is => 'ro', search => 1, pk => 1 );
field id_user => (
    is     => 'ro',
    search => 1,
    fk     => [qw/RSS::Social::User id users sessions/]
);
field uuid            => ( is => 'ro', search => 1 );
field bcrypted_secret => ( is => 'ro' );
field created => (
    is        => 'ro',
    search    => 1,
    converter => RSS::Social::DB::Converter::DateTime->new
);

fix;

sub generate_for_user {
    my ( $self, $user )       = @_;
    my ( $secret, $bcrypted ) = RSS::Social::UserSecret->new->generate_random;
    my $uuid         = uuid4();
    my $user_session = RSS::Social::UserSession::Instance->new(
        uuid            => $uuid,
        bcrypted_secret => $bcrypted,
        id_user         => $user->id,
    );
    RSS::Social::UserSession->insert($user_session);
    ($user_session) = @{ RSS::Social::UserSession->search( uuid => $uuid ) };
    return ( $user_session, $secret );
}

sub recover_auth {
    my $self = shift;
    my ( $uuid, $secret ) = @_;
    my ($user_session) = @{
        $self->search(
            uuid    => $uuid,
            created => { '>' => \[ 'now() - ?::interval', '1 day' ] },
        )
    };
    return if !$user_session;
    if (
        !RSS::Social::UserSecret->new->check(
            $secret, $user_session->bcrypted_secret
        )
      )
    {
        return;
    }
    return $user_session;

}
1;
