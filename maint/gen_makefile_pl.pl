#!/usr/bin/env perl
# ABSTRACT: Generate a Makefile.PL from a cpanfile

use Data::Dumper qw( Dumper );

use lib 'maint/lib';

use KENTNL::DumpAs qw( dump_as );
use KENTNL::DistMeta;

my $distmeta = KENTNL::DistMeta->new();

my $perl_prereq = $distmeta->perl_prereq;

my %TDATA = (
    generated_by       => 'maint/gen_makefile_pl.pl',
    use_perl           => ( ($perl_prereq) ? qq[use $perl_prereq;] : '' ),
    eumm_version       => '',
    writemakefile_args => dump_as(
        '*WriteMakefileArgs' => {
            DISTNAME => $distmeta->name,
            NAME     => $distmeta->main_module,
            AUTHOR   => $distmeta->author,
            ABSTRACT => $distmeta->abstract,
            VERSION  => $distmeta->version,
            LICENSE  => $distmeta->license_object->meta_yml_name,
        }
    ),
);
print Dumper( \%TDATA );

