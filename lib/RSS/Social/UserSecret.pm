package RSS::Social::UserSecret;

use v5.42.0;
use strict;
use warnings;

use Moo;
use Crypt::URandom qw/urandom/;
use Crypt::Bcrypt qw/bcrypt_prehashed bcrypt_check_prehashed/;
use Digest::SHA qw/sha512_hex/;

sub generate_random {
	my $self = shift;
	my $secret = unpack 'H*', urandom(72 / 2);
	my $to_store = $self->hash($secret);
	return ($secret, $to_store);
}

sub hash {
	my ($self, $secret, $is_bcrypt) = @_;
	my $to_store;
	if ($is_bcrypt) {
		return bcrypt_prehashed($secret, '2b', 12, urandom(16), 'sha256');
	}
	return sha512_hex($secret);
}

sub check {
	my ($self, $secret, $stored, $is_bcrypt) = @_;
	if ($is_bcrypt) {
		return bcrypt_check_prehashed($secret, $stored);
	}
	return sha512_hex($secret) eq $stored;
}
1;
