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

sub _prelude {
    my ( $package, $file, $line ) = @_;
    return qq[package $package;\n] . qq[#line $line \"$file\"\n];
}
sub _cache_key { join qq[\0], @_ }

sub _fun_can {
    return $_[0] if 'CODE' eq ref $_[0];
    my ( $package, $function ) = $_[0] =~ /\A(.*?)::([^:]+)\z/;
    return $package->can($function);
}

sub _gen_sub {
    my ( $prelude, $code ) = @_;
    my $sub_code = $prelude . 'sub {' . $code . '};';
    local $@;
    my $sub = eval $sub_code;
    $@ or return $sub;
    die "Can't compile trampoline: $@\n code => $sub_code";
}

my $method_trampoline_cache   = {};
my $function_trampoline_cache = {};

sub call_method_from {
    my @caller = _to_caller( $_[0] );
    return ( $method_trampoline_cache->{ _cache_key(@caller) } ||=
          _gen_sub( _prelude(@caller), q[ $_[0]->${\$_[1]}( @_[2..$#_ ] ) ] ) );
}

sub call_function_from {
    my @caller = _to_caller( $_[0] );
    return ( $function_trampoline_cache->{ _cache_key(@caller) } ||=
          _gen_sub( _prelude(@caller), q[ _fun_can($_[1])->( @_[2..$#_ ] ) ] )
    );
}

=head1 NAME

Call::From - Call functions/methods with a fake caller()

