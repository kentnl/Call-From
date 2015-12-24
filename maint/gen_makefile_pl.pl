#!/usr/bin/env perl
# ABSTRACT: Generate a Makefile.PL from a cpanfile

use Data::Dumper qw( Dumper );

use lib 'maint/lib';

use KENTNL::DistMeta;
use KENTNL::EUMM;
use Path::Tiny qw( path );

my $distmeta = KENTNL::DistMeta->new();
my $eumm = KENTNL::EUMM->new( distmeta => $distmeta );

path('./Makefile.PL')->spew_raw( $eumm->filled_template );
