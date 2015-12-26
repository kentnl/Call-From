use strict;
use warnings;

use Test::More;

# ABSTRACT: Check call_method_from behaviour

{

    package KENTNL::Dud;

    sub get_self {
        return $_[0];
    }

    sub get_args {
        return [ @_[ 1 .. $#_ ] ];
    }

    sub get_caller {
        return [ caller() ];
    }
}

use Call::From qw( call_method_from );

my $frame = [ 'KENTNL::Fake::Package', 'misleading', '9001' ];

is( KENTNL::Dud->${ \call_method_from($frame) }('get_self'),
    'KENTNL::Dud', 'Invocant passthrough' );

is_deeply(
    KENTNL::Dud->${ \call_method_from($frame) }( 'get_args', 1, 2, 3, 4 ),
    [ 1, 2, 3, 4 ],
    'Argument passthrough'
);

is_deeply( KENTNL::Dud->${ \call_method_from($frame) }('get_caller'),
    $frame, 'Caller Spoofing worked' );

done_testing;

