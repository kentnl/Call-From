use 5.006;    # our
use strict;
use warnings;

package KENTNL::DistMeta;

# ABSTRACT: Glue layer around interpreting distmeta.json and cpanfile

use JSON::MaybeXS qw();
use Path::Tiny qw( path );
use KENTNL::PMFiles qw( pm_files );
use KENTNL::TestDirs qw();
use KENTNL::NameShift qw( path_to_module module_to_distname module_to_path );
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

sub testdir {
    my $testdir = ( $_[0]->{testdir} || './t' );
    $testdir =~ s/\/?$//;
    return $testdir;
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
    return $_[0]->{perl_prereq} if $_[0]->{perl_prereq};

    my $prereqs = $_[0]->prereqs;
    my $prereq =
      $prereqs->requirements_for(qw(runtime requires))
      ->clone->add_requirements(
        $prereqs->requirements_for(qw(configure requires)) )
      ->add_requirements( $prereqs->requirements_for(qw(build requires)) )
      ->add_requirements( $prereqs->requirements_for(qw(test requires)) )
      ->as_string_hash->{perl};
    if ($prereq) {
        require version;
        $prereq = version->parse($prereq)->numify;
    }
    return ( $_[0]->{perl_prereq} = $prereq );
}

sub distmeta {
    return ( $_[0]->{_distmeta} ||=
          $json->decode( path( $_[0]->filename )->slurp_raw() ) );
}

sub abstract {
    return ( $_[0]->{abstract} ||=
          ( $_[0]->distmeta->{abstract} or $_[0]->abstract_from_main_module ) );
}

sub abstract_from_main_module {
    require KENTNL::Abstracts;
    return KENTNL::Abstracts::abstract_from_file(
        module_to_path( $_[0]->main_module, $_[0]->libdir ) );

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
    return ( $_[0]->{authors} ||= ( $_[0]->distmeta->{authors} || [] ) );
}

sub author {
    return ( $_[0]->{author} ||= join q[, ], @{ $_[0]->authors } );
}

sub version_check {
    my ( $self, $version ) = @_;
    $_[0]->{version_check} ||= sub {
        my ($orig_version) = @_;
        if ( $orig_version !~ /\A\d+[.]\d{6}\z/ ) {
            croak("$orig_version is does not match \\d+ . \\d{6}");
        }
        return $orig_version;
    };
    return $_[0]->{version_check}->($version);
}

sub version {
    return $_[0]->version_check(
        $_[0]->{version} ||= (
                 $_[0]->version_from_env
              or $_[0]->distmeta->{version}
              or $_[0]->version_from_main_module
        )
    );
}

sub version_from_env {
    return $ENV{V} if defined $ENV{V};
    return;
}

sub version_from_main_module {
    require Module::Metadata;
    my $mm = Module::Metadata->new_from_file(
        path_to_module( $_[0]->main_module, $_[0]->libdir ) );
    ( $mm and defined $mm->version )
      or croak "Can't extract \$VERSION from " . $_[0]->main_module;
    return $mm->version();
}

sub license_class {
    return $_[0]->{license_class} if $_[0]->{license_class};
    if ( exists $_[0]->distmeta->{license} ) {
        if ( $_[0]->distmeta->{license} =~ /^=(.*$)/ ) {
            return ( $_[0]->{license_class} = "$1" );
        }
        return ( $_[0]->{license_class} =
              "Software::License::" . $_[0]->distmeta->{license} );
    }
    croak "license not defined";
    return;
}

sub license_object {
    return $_[0]->{license_object} if $_[0]->{license_object};
    my $class = $_[0]->license_class;
    eval "require $class;1" or die $@;
    return (
        $_[0]->{license_object} = $class->new(
            {
                holder => $_[0]->copyright_holder,
                year   => $_[0]->copyright_year,
            }
        )
    );
}

sub copyright_holder {
    return ( $_[0]->{copyright_holder} ||=
          ( $_[0]->distmeta->{copyright_holder} or $_[0]->authors->[0] ) );
}

sub copyright_year {
    return ( $_[0]->{copyright_year} ||=
          ( $_[0]->distmeta->{copyright_year} or (localtime)[5] + 1900 ) );
}

sub eumm_extra {
   return ( $_[0]->{eumm_extra} ||= ( $_[0]->distmeta->{eumm_extra} or {} ) )
}

sub test_dirs {
  return ( $_[0]->{test_dirs} ||= [ KENTNL::TestDirs::test_dirs( $_[0]->testdir ) ] );
}
1;

