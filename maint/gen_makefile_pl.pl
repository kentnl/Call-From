#!/usr/bin/env perl
# ABSTRACT: Generate a Makefile.PL from a cpanfile

use Path::Tiny qw( path );
use Data::Dumper qw( Dumper );
use JSON::MaybeXS;
use Module::CPANfile;

use lib 'maint/lib';

use KENTNL::DumpAs qw( dump_as );
use KENTNL::DistMeta;

my $json     = JSON::MaybeXS->new( { utf8 => 1, } );
my $distmeta = KENTNL::DistMeta->new();
my $cpanfile = Module::CPANfile->load('cpanfile');

my $prereqs = $cpanfile->prereqs;

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
        }
    ),
);
print Dumper( \%TDATA );

