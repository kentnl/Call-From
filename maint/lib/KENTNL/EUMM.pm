use 5.006;

use strict;
use warnings;

package KENTNL::EUMM;
use Carp qw( carp croak );
use KENTNL::DumpAs qw( dump_as );

# ABSTRACT: an EUMM Templating generator

sub new {
    bless { ref $_[1] ? %{ $_[1] } : @_[ 1 .. $#_ ] }, $_[0];
}

sub template_name {
    return ( $_[0]->{template_name} ||= './maint/eumm.tpl' );
}

sub distmeta {
    return $_[0]->{distmeta} if exists $_[0]->{distmeta};
    require KENTNL::DistMeta;
    return ( $_[0]->{distmeta} = KENTNL::DistMeta->new() );
}

sub _version_eumm {
    my ( $module, $v ) = @_;
    require version;
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
    return $v;
}

sub require_prereqs {
    my $prereqs = $_[0]->distmeta->prereqs->clone;
    my $merged  = $_[0]->_merged_prereqs;

    # second pass: update from merged requirements
    for my $phase (qw/runtime build test/) {
        my $req = $prereqs->requirements_for( $phase, 'requires' );
        for my $mod ( $req->required_modules ) {
            $req->clear_requirement($mod);
            $req->add_string_requirement(
                $mod => $merged->requirements_for_module($mod) );
        }
    }

    my %required;
    for my $phase (qw( configure build test runtime )) {
        my $phase_requires =
          $prereqs->requirements_for( $phase, 'requires' )
          ->clone->clear_requirement('perl')->as_string_hash;
        $required{$phase} = {
            map { $_ => _version_eumm( $_, $phase_requires->{$_} ) }
              keys %{$phase_requires}
        };
    }
    return \%required;
}

sub _merged_prereqs {
    my $prereqs = $_[0]->distmeta->prereqs->clone;
    require CPAN::Meta::Requirements;
    my $merged = CPAN::Meta::Requirements->new();

    # first pass: generated merged requirements
    for my $phase (qw/runtime build test/) {
        my $req = $prereqs->requirements_for( $phase, 'requires' );
        $merged->add_requirements($req);
    }
    return $merged;
}

sub fallback_prereq_pm {
    my $prereqs = $_[0]->_merged_prereqs->as_string_hash;
    return {
        map { $_ => _version_eumm( $_, $prereqs->{$_} ) }
          keys %{$prereqs}
    };
}

sub writemakefile_args {
    return ( $_[0]->{writemakefile_args} ||= $_[0]->build_writemakefile_args );
}

sub build_writemakefile_args {
    my $distmeta  = $_[0]->distmeta;
    my $required  = $_[0]->require_prereqs;
    my %EUMM_META = (
        DISTNAME           => $distmeta->name,
        NAME               => $distmeta->main_module,
        AUTHOR             => $distmeta->author,
        ABSTRACT           => $distmeta->abstract,
        VERSION            => $distmeta->version,
        LICENSE            => $distmeta->license_object->meta_yml_name,
        CONFIGURE_REQUIRES => $required->{configure},
        PREREQ_PM          => $required->{runtime},
        test               => {
            TESTS => ( join q{ }, map { "$_/.*" } @{ $distmeta->test_dirs } )
        },
    );
    $EUMM_META{BUILD_REQUIRES} = $required->{build}
      if keys %{ $required->{build} };
    $EUMM_META{TEST_REQUIRES} = $required->{test}
      if keys %{ $required->{test} };

    if ( my $perl_prereq = $distmeta->perl_prereq ) {
        $EUMM_META{MIN_PERL_VERSION} = $perl_prereq;
    }

    %EUMM_META = ( %EUMM_META, %{ $distmeta->eumm_extra } );

    return \%EUMM_META;
}

sub template_stash {
    return ( $_[0]->{template_stash} ||= $_[0]->build_template_stash );
}

sub build_template_stash {
    my $perl_prereq = $_[0]->distmeta->perl_prereq;
    return {
        generated_by => __PACKAGE__,
        use_perl     => ( ($perl_prereq) ? qq[use $perl_prereq;] : '' ),
        eumm_version => '',
        WriteMakefile_args =>
          dump_as( '*WriteMakefile_args' => $_[0]->writemakefile_args ),
        fallback_prereqs =>
          dump_as( '*FallbackPrereqs' => $_[0]->fallback_prereq_pm ),
        preamble      => '',
        mutate_config => '',
        postamble     => '',
    };
}

sub filled_template {
    require Text::Template;
    my $delim = ( $_[0]->{delim} ||= [qw( {{ }} )] );
    my $tmpl = Text::Template->new(
        TYPE       => 'FILE',
        SOURCE     => $_[0]->template_name,
        DELIMITERS => $delim,
        BROKEN     => sub {
            my %hash = @_;
            croak( $hash{error} );
        }
    );
    croak( "Can't create Text::Template object from " . $_[0]->template_name )
      unless $tmpl;

    my $result = $tmpl->fill_in( HASH => $_[0]->template_stash );

    croak( "Filling in template returned undef from  " . $_[0]->template_name )
      unless defined $result;

    return $result;
}
1;

