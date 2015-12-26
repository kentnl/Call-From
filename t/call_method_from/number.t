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
use constant '_file' => sub { [ caller() ]->[1] }
  ->();

subtest "call_method_from(0)" => sub {
    use Call::From qw( call_method_from );

#line 1000
    my $result = KENTNL::Dud->${ \call_method_from(0) }('get_self');
#line 33
    is( $result, 'KENTNL::Dud', 'Invocant passthrough' );

#line 2000
    $result = KENTNL::Dud->${ \call_method_from(0) }( 'get_args', 1, 2, 3, 4 ),
#line 38
      is_deeply( $result, [ 1, 2, 3, 4 ], 'Argument passthrough' );

#line 3000
    $result = KENTNL::Dud->${ \call_method_from(0) }('get_caller');
#line 43
    is_deeply( $result, [ 'main', _file, 3000 ],
        'Caller transferrance worked' );
};
{

    package KENTNL::Mirror;
    use Call::From qw( call_method_from );

    sub indirect {
#line 4000
        return KENTNL::Dud->${ \call_method_from(1) }(@_);
#line 55
    }

    sub double_indirect {
#line 5000
        return KENTNL::Dud->${ \call_method_from(2) }(@_);
#line 61
    }
}
{

    package KENTNL::Mirror::Double;
    use Call::From qw( call_method_from );

    sub indirect {
#line 6000
        return KENTNL::Mirror::double_indirect(@_);
#line 72
    }

}
subtest "call_method_from(1)" => sub {
    my $indirect = KENTNL::Mirror->can('indirect');

#line 7000
    my $result = $indirect->('get_self');
#line 81
    is( $result, 'KENTNL::Dud', 'Invocant passthrough' );

#line 8000
    $result = $indirect->( 'get_args', 1, 2, 3, 4 );
#line 86
    is_deeply( $result, [ 1, 2, 3, 4 ], 'Argument passthrough' );

#line 9000
    $result = $indirect->('get_caller');
#line 91
    is_deeply( $result, [ 'main', _file, 9000 ],
        'Caller transferrance worked' );
};

subtest "call_method_from(2)" => sub {
    my $indirect = KENTNL::Mirror::Double->can('indirect');

#line 10000
    my $result = $indirect->('get_self');
#line 101
    is( $result, 'KENTNL::Dud', 'Invocant passthrough' );

#line 11000
    $result = $indirect->( 'get_args', 1, 2, 3, 4 );
#line 105
    is_deeply( $result, [ 1, 2, 3, 4 ], 'Argument passthrough' );

#line 12000
    $result = $indirect->('get_caller');
#line 111
    is_deeply(
        $result,
        [ 'main', _file, 12000 ],
        'Caller transferrance worked'
    );
};
done_testing;

