package RSS::Social::User;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;
use RSS::Social::Admin;
use RSS::Social::RSSItem;
use RSS::Social::DB::Converter::DateTime;
use DateTime::Format::Duration;
use UUID qw/uuid4/;

require RSS::Social::UserPermission;

sub dbh {
    return RSS::Social::DB->connect;
}

table 'users';

field id        => ( is => 'ro', pk     => 1, search   => 1 );
field uuid      => ( is => 'ro', search => 1, required => 1 );
field user_name => ( is => 'rw', search => 1, column   => 'username' );
field password  => ( is => 'rw', search => 1 );
field name      => ( is => 'rw' );
field surname   => ( is => 'rw' );
field country   => ( is => 'rw' );
field city      => ( is => 'rw' );
field bio      => ( is => 'rw' );
field id_admin => (
    is     => 'rw',
    search => 1,
    fk     => [qw/RSS::Social::Admin id admins users/]
);
field creation_time => (
    is        => 'ro',
    search    => 1,
    converter => RSS::Social::DB::Converter::DateTime->new,
);
field last_connection => (
    is        => 'rw',
    search    => 1,
    converter => RSS::Social::DB::Converter::DateTime->new,
);
field is_enabled => (
    is     => 'rw',
    search => 1,
);

fix;

instance_has _cached_permissions => ( is => 'rw' );

instance_sub is_admin => sub {
    my ($self) = @_;
    my @admins = @{ $self->admins };
    if (@admins) {
        return 1;
    }
    return 0;
};

instance_sub permissions => sub {
    my ($self) = @_;
    require RSS::Social::Permission;
    if ( !defined $self->_cached_permissions ) {
        my @permissions = @{ RSS::Social::Permission->free_search(
                -join => [
                    qw/permissions.id=user_permissions.id_permission user_permissions
                      user_permissions.id_user=users.id users/
                ],
                -where => {
                    'users.id' => $self->id,
                }
            )
        };
        $self->_cached_permissions(
            {
                map { ( $_->slug => $_ ) }
                  @permissions

            }
        );
    }
    return %{ $self->_cached_permissions };
};

sub add_permission {
    my ( $self, $instance, $slug, $name, $description ) = @_;
    if ( 3 > scalar @_ ) {
        die 'add_permission: $self, $instance, $slug, [$name], [$description]';
    }
    $name        //= '';
    $description //= '';
    eval {
        my $uuid = uuid4();

        # May already exist, harmless
        RSS::Social::Permission->insert(
            RSS::Social::Permission::Instance->new(
                uuid        => $uuid,
                slug        => $slug,
                name        => $name,
                description => $description
            )
        );
    };
    if ($@) {
        if ( $@ !~ /duplicate/ ) {
            warn $@;
        }
    }
    my ($permission) = @{ RSS::Social::Permission->search( slug => $slug ) };
    eval {
        my $uuid = uuid4();
        RSS::Social::UserPermission->insert(
            RSS::Social::UserPermission::Instance->new(
                uuid          => $uuid,
                id_user       => $instance->id,
                id_permission => $permission->id
            )
        );
    };
    if ($@) {
        if ( $@ !~ /duplicate/ ) {
            warn $@;
        }
    }

}

sub make_admin {
    my ( $self, $instance ) = @_;
    my $admin_uuid = uuid4();
    RSS::Social::Admin->insert(
        RSS::Social::Admin::Instance->new( uuid => $admin_uuid ) );
    my @admins = @{ RSS::Social::Admin->search( uuid => $admin_uuid ) };
    die 'Couldn\'t create admin row' if !@admins;
    my $admin = $admins[0];
    $instance->id_admin( $admin->id );
    RSS::Social::User->update( $instance, 'id_admin' );
    return $instance->fetch_again;
}

instance_sub rss_items => sub {
    my $self = shift;
    require RSS::Social::UserLoginUrl;
    require RSS::Social;
    my $minimum_account_time = DateTime->now->add( minutes => -5 );
    if ( $self->creation_time > $minimum_account_time ) {
	    say 'hola';
        my $duration        = $self->creation_time - $minimum_account_time;
        my $duration_format = DateTime::Format::Duration->new(
            pattern => '%M:%S Remaining for your account to be activated' );
        return (
            RSS::Social::RSSItem->new(
                title       => $duration_format->format_duration( $duration, ),
                link        => RSS::Social->new->config->{base_url},
                description => '',
                guid        => '/activation/'
                  . $duration_format->format_duration($duration) . '/'
                  . $self->uuid,
            )
        );
    }
    my ($login_url) = @{ RSS::Social::UserLoginUrl->search(
            created => { '>', \'now() - interval \'10 minutes\'' },
            id_user => $self->id,
            used    => 0,
        )
    };
    my @items;
    if ( !$login_url ) {
        my $secret;
        ( $login_url, $secret ) =
          RSS::Social::UserLoginUrl->generate_for_user($self);
        push @items,
          RSS::Social::RSSItem->new(
            title       => 'Login with this link',
            description =>
'Do not share this url with anyone or they will have access to your account',
            link => RSS::Social->new->config->{base_url}
              . '/fast-login/'
              . $login_url->uuid . '/'
              . $secret,
          );
    }
    return @items;
};
1;
