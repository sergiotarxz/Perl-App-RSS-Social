package RSS::Social::DB::Converter::UTF8;

use v5.42.0;
use strict;
use warnings;

use Moo;
use DateTime::Format::Pg;
use Encode qw/decode encode/;

sub to_db {
	shift;
	return encode 'utf-8', shift;
}

sub from_db {
	shift;
	return decode 'utf-8', shift;
}

with 'DBIx::Quick::Converter';
1;
