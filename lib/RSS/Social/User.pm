package RSS::Social::User;

use v5.42.0;
use strict;
use warnings;

use DBIx::Quick;
use RSS::Social::DB;
use RSS::Social::Admin;
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
field id_admin => (
    is     => 'rw',
    search => 1,
    fk     => [qw/RSS::Social::Admin id admins users/]
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
1;
