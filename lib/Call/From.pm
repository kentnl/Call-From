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
    my ($context) = @_;
    my (@call)    = caller(1);
    return ( @{$context}, @call[ scalar @{$context} .. $#call ] )
      if ref $context;
    return caller( $context + 1 ) if defined $context and $context =~ /^-?\d+$/;
    $call[0] = $context if defined $context;
    return @call;
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
    return $method_trampoline_cache->{ _cache_key( _to_caller( $_[0] ) ) } ||=
      _gen_sub(
        _prelude( _to_caller( $_[0] ) ),
        q[ $_[0]->${\$_[1]}( @_[2..$#_ ] ) ]
      );
}

sub call_function_from {
    return $function_trampoline_cache->{ _cache_key( _to_caller( $_[0] ) ) }
      ||= _gen_sub(
        _prelude( _to_caller( $_[0] ) ),
        q[ _fun_can($_[1])->( @_[2..$#_ ] ) ]
      );
}

=head1 NAME

Call::From - Call functions/methods with a fake caller()

