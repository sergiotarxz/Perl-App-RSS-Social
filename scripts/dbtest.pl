#!/usr/bin/env perl

use v5.42.0;
use strict;
use warnings;

use RSS::Social::User;
use RSS::Social::Admin;
use RSS::Social::Topic;
use RSS::Social::Messages;
use UUID qw/uuid4/;
use Data::Dumper;

my $uuid = uuid4();
say 'This uuid ' . $uuid;
my $user_before_insert = RSS::Social::User::Instance->new( uuid => $uuid );
RSS::Social::User->insert($user_before_insert);
my ($user) = @{ RSS::Social::User->search( uuid => $uuid ) };

say 'Is this user admin? ' . $user->is_admin;
say 'Making admin';
RSS::Social::User->make_admin($user);
$user = $user->fetch_again;
say 'Is this user admin? ' . $user->is_admin;
say 'Current permissions';
print Data::Dumper::Dumper { $user->permissions };
say 'Adding to vividor';
RSS::Social::User->add_permission( $user, 'vividor', 'Vividor',
    'Puede salir de fiesta' );
$user = $user->fetch_again;
say 'Current permissions';
print Data::Dumper::Dumper { $user->permissions };
$uuid = uuid4();
eval {
    RSS::Social::Topic->insert(
        RSS::Social::Topic::Instance->new(
            uuid        => $uuid,
            slug        => 'hola-topic',
            name        => 'Hola Topic',
            description => 'This is the Hola Topic'
        )
    );
};
my ($topic) = @{ RSS::Social::Topic->search( slug => 'hola-topic' ) };
RSS::Social::Messages->insert(
    RSS::Social::Messages::Instance->new(
        uuid            => uuid4(),
        text            => 'hola',
        id_topic        => $topic->id,
        id_user_creator => $user->id
    )
);
