#!/usr/bin/env perl
# FILENAME: gen_deps.pl
# CREATED: 12/24/15 18:16:46 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Generate a cpanfile by skimming your source tree

use strict;
use warnings;

use PIR;

use lib 'maint/lib';

use KENTNL::Prereqr;

my $prereqr = KENTNL::Prereqr->new(
    rules => [
        {
            rule     => PIR->new->max_depth(1)->perl_file->name('Makefile.PL'),
            start_in => [''],
            deps_to  => [ 'configure', 'requires' ],
        },
        {
            rule     => PIR->new->perl_file,
            start_in => ['inc'],
            deps_to  => [ 'configure', 'requires' ],
        },
        {
            rule        => PIR->new->perl_module,
            start_in    => ['inc'],
            provides_to => ['configure'],
        },
        {
            rule     => PIR->new->perl_file,
            start_in => ['lib'],
            deps_to  => [ 'runtime', 'requires' ],
        },
        {
            rule        => PIR->new->perl_module,
            start_in    => ['lib'],
            provides_to => [ 'runtime', 'test' ],
        },
        {
            rule     => PIR->new->perl_file,
            start_in => ['maint'],
            deps_to  => [ 'develop', 'requires' ],
        },
        {
            rule        => PIR->new->perl_module,
            start_in    => ['maint'],
            provides_to => ['develop'],
        },
        {
            rule     => PIR->new->perl_file,
            start_in => ['t'],
            deps_to  => [ 'test', 'requires' ],
        },
        {
            rule        => PIR->new->perl_module,
            start_in    => ['t'],
            provides_to => ['test'],
        }
    ]
);

my ( $prereqs, $provided ) = $prereqr->collect;

use Module::CPANfile;

my $cpanfile =
  Module::CPANfile->from_prereqs( $prereqr->prereqs->as_string_hash );
$cpanfile->save('cpanfile');
