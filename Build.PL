#!/usr/bin/env perl
use Module::Build;

my $build = Module::Build->new(
    module_name   => 'RSS::Social',
    license       => 'AGPLv3',
    dist_author   => 'Sergio Iglesias <sergioxz@cpan.org>',
    dist_abstract => 'A social network with RSS as main character',
    requires      => {
        'Mojolicious'                => 0,
        'UUID'                       => 0,
        'Moo'                        => 0,
        'SQL::Abstract::More'        => 0,
        'DBI'                        => 0,
        'DBD::Pg'                    => 0,
        'JSON'                       => 0,
        'Import::Into'               => 0,
        'Crypt::Bcrypt'              => 0,
        'Crypt::URandom'             => 0,
        'DateTime::Format::HTTP'     => 0,
        'DateTime::Format::Pg'       => 0,
        'DateTime'                   => 0,
        'DateTime::Format::Duration' => 0,
        'Wiki::JSON'                 => 0,
        'Cpanel::JSON::XS'           => 0,
        'Path::Tiny'                 => 0,
        'File::pushd'                => 0,
        'DateTime::Format::ISO8601'  => 0,
        'DBIx::Quick'                => 0,
        'DBIx::Auto::Migrate'        => 0,
    },
);
$build->create_build_script;
