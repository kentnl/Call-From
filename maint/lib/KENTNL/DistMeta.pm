use 5.006;    # our
use strict;
use warnings;

package KENTNL::DistMeta;

# ABSTRACT: Glue layer around interpreting distmeta.json

use JSON::MaybeXS qw();
use Path::Tiny qw( path );
use KENTNL::PMFiles qw( pm_files );
use KENTNL::NameShift qw( path_to_module module_to_distname );
use Carp qw( croak carp );
use Module::CPANfile;

my $json = JSON::MaybeXS->new( { utf8 => 1, } );

sub new {
    bless { ref $_[1] ? %{ $_[1] } : @_[ 1 .. $#_ ] }, $_[0];
}

sub filename {
    return ( $_[0]->{filename} ||= './maint/distmeta.json' );
}

sub libdir {
    my $libdir = ( $_[0]->{libdir} ||= './lib' );
    $libdir =~ s/\/?$//;
    return $libdir;
}

sub cpanfile {
    return ( $_[0]->{cpanfile} ||= './cpanfile' );
}

sub cpanfile_data {
    return ( $_[0]->{cpanfile_data} ||=
          Module::CPANfile->load( $_[0]->cpanfile ) );
}

sub prereqs {
    return $_[0]->cpanfile_data->prereqs;
}

sub perl_prereq {
    my $prereqs = $_[0]->prereqs;
    $prereqs->requirements_for(qw(runtime requires))
      ->clone->add_requirements(
        $prereqs->requirements_for(qw(configure requires)) )
      ->add_requirements( $prereqs->requirements_for(qw(build requires)) )
      ->add_requirements( $prereqs->requirements_for(qw(test requires)) )
      ->as_string_hash->{perl};
}

sub distmeta {
    return ( $_[0]->{_distmeta} ||=
          $json->decode( path( $_[0]->filename )->slurp_raw() ) );
}

sub abstract {
  return ( $_[0]->{abstract} ||= ( $_[0]->distmeta->{abstract} or $_[0]->abstract_from_main_module ));
}

sub main_module {
    return (
        $_[0]->{main_module} ||= (
            $_[0]->distmeta->{main_module}
              or exists $_[0]->distmeta->{name}
            ? $_[0]->main_module_like_distname
            : $_[0]->main_module_shortest_pmfile
        )
    );
}

sub main_module_like_distname {
    my $distmeta        = $_[0]->distmeta;
    my $libdir          = $_[0]->libdir;
    my $expected_module = distname_to_module( $distmeta->{name} );
    my $expected_file   = module_to_path( $expected_module, $_[0]->libdir );
    if ( grep { $_ =~ /\Q$expected_file\E$/ } pm_files($libdir) ) {
        carp "Guessed main module is $expected_module";
        return $expected_module;
    }
    carp( join qq[\n], pm_files($libdir) );
    croak(
"No file matching $expected_file, can't guess main module, \"name\" => correct?"
    );
}

sub main_module_shortest_pmfile {
    my $libdir = $_[0]->libdir;
    my (@files) = pm_files($libdir);
    if ( not @files ) {
        croak("No files in $libdir to guess main module from");
    }
    my ( $shortest, @rest ) = sort { length $a <=> length $b } @files;
    my $shortest_module = path_to_module( $shortest, $libdir );
    carp "Guessed main module is $shortest_module from $shortest";
    return $shortest_module;
}

sub name {
    return (
        $_[0]->{name} ||= (
            $_[0]->distmeta->{name}
              or module_to_distname( $_[0]->main_module )
        )
    );
}

sub authors {
    return @{ $_[0]->{authors} ||= ( $_[0]->distmeta->{authors} || [] ) };
}

sub author {
    return ( $_[0]->{author} ||= join q[, ], $_[0]->authors );
}

1;

