package RSS::Social::UserSecret;

use v5.42.0;
use strict;
use warnings;

use Moo;
use Crypt::URandom qw/urandom/;
use Crypt::Bcrypt qw/bcrypt_prehashed bcrypt_check_prehashed/;

sub generate_random {
	my $self = shift;
	my $secret = unpack 'H*', urandom(72 / 2);
	my $to_store = $self->hash($secret);
	return ($secret, $to_store);
}

sub hash {
	my ($self, $secret) = @_;
	my $to_store = bcrypt_prehashed($secret, '2b', 12, urandom(16), 'sha256');
	return $to_store;
}

sub check {
	my ($self, $secret, $stored) = @_;
	return bcrypt_check_prehashed($secret, $stored);
}
1;
