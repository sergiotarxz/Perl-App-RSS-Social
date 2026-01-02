package RSS::Social::DB;

use v5.42.0;
use strict;
use warnings;

use DBIx::Auto::Migrate;

finish_auto_migrate;

my $dbh;

{
	my $dbname;
	sub dsn {
		if (!defined $dbname) {
			require RSS::Social;
			$dbname = RSS::Social->new->config->{db}{dbname};
		}
		return "dbi:Pg:dbname=$dbname";
	}
}

sub user {
	return undef;
}

sub pass {
	return undef;
}

sub migrations {
    return (
        'CREATE TABLE options (
		id BIGSERIAL PRIMARY KEY,
                name TEXT,
                value TEXT,
		UNIQUE (name)
        );',
	create_index(qw/options name/),
	'CREATE TABLE users (
		id BIGSERIAL PRIMARY KEY,
		uuid TEXT NOT NULL,
		username TEXT NULL,
		password TEXT NULL,
		name TEXT NULL,
		surname TEXT NULL,
		city TEXT NULL,
		country TEXT NULL,
		id_admin BIGINT NULL,
		creation_time timestamp DEFAULT NOW(),
		last_connection timestamp DEFAULT NOW(),
		is_enabled INT DEFAULT 0,
		UNIQUE (uuid),
		UNIQUE (username),
		UNIQUE (id_admin)
	);',
	create_index(qw/users uuid/),
	create_index(qw/users username/),
	create_index(qw/users creation_time/),
	create_index(qw/users last_connection/),
	create_index(qw/users is_enabled/),
	'CREATE TABLE admins (
		id BIGSERIAL PRIMARY KEY,
		uuid TEXT NOT NULL,
		UNIQUE (uuid)
	)',
	create_index(qw/admins uuid/),
	create_index(qw/users id_admin/),
	'CREATE TABLE permissions (
		id BIGSERIAL PRIMARY KEY,
		uuid TEXT NOT NULL,
		slug TEXT NOT NULL,
		name TEXT NULL,
		description TEXT NULL,
		UNIQUE (slug),
		UNIQUE (uuid)
	)',
	create_index(qw/permissions slug/),
	'CREATE TABLE user_permissions (
		id BIGSERIAL PRIMARY KEY,
		uuid TEXT NOT NULL,
		id_user BIGINT NOT NULL,
		id_permission BIGINT NOT NULL,
		extra_var1 TEXT NULL,
		extra_var2 TEXT NULL,
		extra_var3 TEXT NULL,
		UNIQUE (id_user, id_permission),
		UNIQUE (uuid)
	)',
	create_index(qw/user_permissions id_user/),
	create_index(qw/user_permissions id_permission/),
	'CREATE TABLE topics (
		id BIGSERIAL PRIMARY KEY,
		uuid TEXT NOT NULL,
		slug TEXT NOT NULL,
		name TEXT NOT NULL,
		description TEXT NOT NULL,
		id_user_created_by BIGINT NULL,
		minimum_account_time_to_post INT DEFAULT 0,
		UNIQUE (uuid),
		UNIQUE (slug)
	)',
	create_index(qw/topics uuid/),
	create_index(qw/topics slug/),
	create_index(qw/topics name/),
	create_index(qw/topics id_user_created_by/),
	'CREATE TABLE rss_urls (
		id BIGSERIAL PRIMARY KEY,
		id_user BIGINT NOT NULL,
		uuid TEXT NOT NULL,
		bcrypted_secret TEXT NOT NULL,
		name TEXT NOT NULL,
		description TEXT NOT NULL,
		UNIQUE (uuid)
	)',
	create_index(qw/rss_urls uuid/),
	create_index(qw/rss_urls name/),
	create_index(qw/rss_urls id_user/),
	'CREATE TABLE rss_url_subscriptions (
		id BIGSERIAL PRIMARY KEY,
		uuid TEXT NOT NULL,
		id_topic BIGINT NOT NULL,
		id_rss_url BIGINT NOT NULL,
		last_fetch timestamp NULL,
		UNIQUE (id_topic, id_rss_url),
		UNIQUE (uuid)
	)',
	create_index(qw/rss_url_subscriptions uuid/),
	create_index(qw/rss_url_subscriptions last_fetch/),
	create_index(qw/rss_url_subscriptions id_topic/),
	create_index(qw/rss_url_subscriptions id_rss_url/),
	'CREATE TABLE messages (
		id BIGSERIAL PRIMARY KEY,
		uuid TEXT NOT NULL,
		id_user_creator BIGINT NOT NULL,
		id_topic BIGINT NOT NULL,
		text TEXT NOT NULL,
		url TEXT NULL,
		image_url TEXT NULL,
		upvotes BIGINT DEFAULT 0,
		downvotes BIGINT DEFAULT 0,
		created timestamp DEFAULT NOW(),
		last_updated_votes timestamp DEFAULT NOW(),
		UNIQUE (uuid)
	)',
	create_index(qw/messages uuid/),
	create_index(qw/messages id_user_creator/),
	create_index(qw/messages url/),
	create_index(qw/messages upvotes/),
	create_index(qw/messages downvotes/),
	create_index(qw/messages image_url/),
	create_index(qw/messages id_topic/),
	create_index(qw/messages created/),
	create_index(qw/messages last_updated_votes/),
	'CREATE TABLE messages_votes (
		id BIGSERIAL PRIMARY KEY,
		uuid TEXT NOT NULL,
		id_user BIGINT NOT NULL,
		id_message BIGINT NOT NULL,
		is_upvote INT NOT NULL,
		UNIQUE (id_user, id_message),
		UNIQUE (uuid)
	)',
	create_index(qw/messages_votes uuid/),
	create_index(qw/messages_votes id_user/),
	create_index(qw/messages_votes id_message/),
	create_index(qw/messages_votes is_upvote/),
	create_index(qw/messages text/),
	'CREATE TABLE users_login_urls (
		id BIGSERIAL PRIMARY KEY,
		id_user BIGINT NOT NULL,
		uuid TEXT NOT NULL,
		bcrypted_secret TEXT NOT NULL,
		used INT DEFAULT 0,
		created timestamp DEFAULT NOW()
	);',
	create_index(qw/users_login_urls id_user/),
	create_index(qw/users_login_urls uuid/),
	create_index(qw/users_login_urls used/),
	create_index(qw/users_login_urls created/),
	'CREATE TABLE users_sessions (
		id BIGSERIAL PRIMARY KEY,
		id_user BIGINT NOT NULL,
		uuid TEXT NOT NULL,
		bcrypted_secret TEXT NOT NULL,
		created timestamp DEFAULT NOW()
	)',
	create_index(qw/users_sessions created/),
	create_index(qw/users_sessions uuid/),
	create_index(qw/users_sessions id_user/),
	'ALTER TABLE users ADD COLUMN bio TEXT NULL',
    );
}

sub create_index {
	my ($table, $column) = @_;
	if (!$table) {
		die 'Index requires table';
	}
	if (!$column) {
		die 'Index requires column';
	}
	return "CREATE INDEX index_${table}_${column} ON $table ($column)";
}

{
	no strict 'refs';
	no warnings 'redefine';
	my $dbh;
	*{"RSS::Social::DB::connect"} = sub {
		if (!defined $dbh) {
			$dbh = connect_cached(@_);
		}
		return $dbh;
	};
}
1;
