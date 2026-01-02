package RSS::Social::DB::Converter::DateTime;

use v5.42.0;
use strict;
use warnings;

use Moo;
use DateTime::Format::Pg;

sub to_db {
	shift;
	my $dt = shift;
      	return undef if !defined $dt;
	return DateTime::Format::Pg->format_datetime($dt);
}

sub from_db {
	shift;
	my $dt = shift;
	return undef if !defined $dt;
	return DateTime::Format::Pg->parse_datetime($dt);
}

with 'DBIx::Quick::Converter';
1;
