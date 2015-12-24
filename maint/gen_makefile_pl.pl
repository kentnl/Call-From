#!/usr/bin/env perl
# ABSTRACT: Generate a Makefile.PL from a cpanfile

use Data::Dumper qw( Dumper );

use lib 'maint/lib';

use KENTNL::DumpAs qw( dump_as );
use KENTNL::DistMeta;

my $distmeta = KENTNL::DistMeta->new();

my $perl_prereq = $distmeta->perl_prereq;

my $required = require_prereqs( $distmeta->prereqs );

my %EUMM_META = (
    DISTNAME           => $distmeta->name,
    NAME               => $distmeta->main_module,
    AUTHOR             => $distmeta->author,
    ABSTRACT           => $distmeta->abstract,
    VERSION            => $distmeta->version,
    LICENSE            => $distmeta->license_object->meta_yml_name,
    CONFIGURE_REQUIRES => $required->{configure},
    PREREQ_PM          => $required->{runtime},
);

$EUMM_META->{BUILD_REQUIRES} = $required->{build}
  if keys %{ $required->{build} };
$EUMM_META->{TEST_REQUIRES} = $required->{test} if keys %{ $required->{test} };

my %TDATA = (
    generated_by => 'maint/gen_makefile_pl.pl',
    use_perl     => ( ($perl_prereq) ? qq[use $perl_prereq;] : '' ),
    eumm_version => '',
    writemakefile_args => dump_as( '*WriteMakefileArgs' => \%EUMM_META ),
);
print Dumper( \%TDATA );

sub require_prereqs {
    my ($prereqs) = @_;
    my %required;
    for my $phase (qw( configure build test runtime )) {
        my $phase_requires =
          $prereqs->requirements_for( $phase, 'requires' )
          ->clone->clear_requirement('perl')->as_string_hash;
        my $phase_required = {};
        for my $module ( keys %{$phase_requires} ) {
            require version;
            my $v = $phase_requires->{$module};
            if ( version::is_strict($v) ) {
                my $version = version->parse($v);
                if ( $version->is_qv ) {
                    if ( ( () = $v =~ /\./g ) > 1 ) {
                        $v =~ s/^v//;
                    }
                    else {
                        $v = $version->numify;
                    }
                }
            }
            carp( 'EUMM cannot parse version ' . $v . ' for ' . $module )
              if !version::is_lax($v);
            $phase_required->{$module} = $v;
        }
        $required{$phase} = $phase_required;
    }
    return \%required;
}
