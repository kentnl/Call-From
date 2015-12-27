use strict;
use warnings;

package Call::From;

our $VERSION   = '0.001000';
our $AUTHORITY = 'cpan:KENTNL';

use Exporter qw();
*import = \&Exporter::import;

our @EXPORT_OK = qw( call_method_from call_function_from $_call_from );

our $_call_from = sub {
    $_[0]->${ \call_method_from( [ _to_caller( $_[1] ) ] ) }( @_[ 2 .. $#_ ] );
};

sub _to_caller {
    my ( $ctx, $offset ) = @_;

    # +1 because this function is internal, and we dont
    # want Call::From
    $offset = 1 unless defined $offset;

    # Numeric special case first because caller is different
    if ( defined $ctx and not ref $ctx and $ctx =~ /^-?\d+$/ ) {

        my (@call) = caller( $ctx + $offset );
        return @call[ 0 .. 2 ];
    }

    my (@call) = caller($offset);

    # _to_caller() returns the calling context of call_method_from
    return @call[ 0 .. 2 ] if not defined $ctx;

    # _to_caller($name) as with (), but with <package> replaced.
    return ( $ctx, $call[1], $call[2] ) if not ref $ctx;

    # _to_caller([ pkg, (file,( line)) ]) fills the fields that are missing
    return (
        $ctx->[0] || $call[0],    # pkg
        $ctx->[1] || $call[1],    # file
        $ctx->[2] || $call[2],    # line
    );

}

sub _fun_can {
    return $_[0] if 'CODE' eq ref $_[0];
    my ( $package, $function ) = $_[0] =~ /\A(.*?)::([^:]+)\z/;
    return $package->can($function);
}

sub _gen_sub {
    my ( $package, $file, $line, $code ) = @_;
    my $sub_code =
        qq[package $package;\n]
      . qq[#line $line \"$file\"\n] . 'sub {'
      . $code . '};';
    local $@;
    my $sub = eval $sub_code;
    $@ or return $sub;
    die "Can't compile trampoline for $package: $@\n code => $sub_code";
}

my $method_trampoline_cache   = {};
my $function_trampoline_cache = {};

sub call_method_from {
    my @caller = _to_caller( $_[0] );
    return ( $method_trampoline_cache->{ join qq[\0], @caller } ||=
          _gen_sub( @caller, q[ $_[0]->${\$_[1]}( @_[2..$#_ ] ) ] ) );
}

sub call_function_from {
    my @caller = _to_caller( $_[0] );
    return (
        $function_trampoline_cache->{ join qq[\0], @caller } ||= _gen_sub(
            @caller, __PACKAGE__ . q[::_fun_can($_[0])->( @_[1..$#_ ] ) ]
        )
    );
}

=head1 NAME

Call::From - Call functions/methods with a fake caller()

=head1 SYNOPSIS

  use Call::From qw( call_method_from );

  my $proxy = call_method_from('Fake::Namespace');

  Some::Class->$proxy( method_name => @args ); # Some::Class->method_name( @args ) with caller() faked.

=head1 DESCRIPTION

Call::From contains a collection of short utility functions to ease calling
functions and methods from faked calling contexts without requiring arcane
knowledge of Perl eval tricks.

=head1 SPECIFYING A CALLING CONTEXT

Calling contexts can be specified in a number of ways.

=head2 Numeric Call Levels

In functions like C<import>, you're most likely wanting to chain caller
meta-data from whoever is calling C<import>

So for instance:

  package Bar;
  sub import {
    my $proxy = call_method_from(1);
    vars->$proxy( import => 'world');
  }
  package Foo;
  Bar->import();

Would trick `vars` to seeing `Foo` as being the calling C<package>, with the line
of the C<< Bar->import() >> call being the C<file> and C<line> of the apparent
caller in C<vars::import>

This syntax is essentially shorthand for

  call_method_from([ caller(1) ])

=head2 Package Name Caller

Strings describing the name of the calling package allows you to conveniently
call functions from arbitrary name-spaces for C<import> reasons, while
preserving the C<file> and C<line> context in C<Carp> stack traces.

  package Bar;
  sub import {
    vars->${\call_method_from('Quux')}( import => 'world');
  }
  package Foo;
  Bar->import();

This example would call C<< vars->import('world') >> from inside the C<Quux>
package, while C<file> and C<line> data would still indicate an origin inside
C<Bar> ( on the line that C<call_method_from> was called on )

This syntax is essentially shorthand for:

  call_method_from([ $package, __FILE__, __LINE__ ])

=head2 ArrayRef of Caller Info

Array References in the form

  [ $package, $file, $line ]

Can be passed as a C<CALLING CONTEXT>. All fields are optional and will be
supplemented with the contents of the calling context when missing.

Subsequently:

  call_method_from([])
    == call_method_from()
    == call_method_from([__PACKAGE__, __FILE__, __LINE__])

  call_method_from(['Package'])
    == call_method_from('Package')
    == call_method_from(['Package', __FILE__, __LINE__])

  call_method_from(['Package','file'])
    == call_method_from(['Package','file', __LINE__])
