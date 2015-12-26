use strict;
use warnings;

use Test::More;

# ABSTRACT: Check _to_caller([])

use Call::From;

sub __file { [caller]->[1] }

subtest "_to_caller(undef,0)" => sub {
    note explain my $result = [ KENTNL::Top::top_function( undef, 0 ) ];
    is( $result->[0], 'KENTNL::DeepChild', '0th frame package' );
    is( $result->[1], __file,              '0th frame file' );
    is( $result->[2], 1000,                '0th frame line' );
};

subtest "_to_caller(undef,1)" => sub {
    note explain my $result = [ KENTNL::Top::top_function( undef, 1 ) ];
    is( $result->[0], 'KENTNL::Child', '1th frame package' );
    is( $result->[1], __file,          '1th frame file' );
    is( $result->[2], 2000,            '1th frame line' );
};

done_testing;

{

    package KENTNL::DeepChild;

    sub child_function {
# line 1000
        my (@result) = Call::From::_to_caller(@_);
    }
}
{

    package KENTNL::Child;

    sub child_function {
# line 2000
        KENTNL::DeepChild::child_function(@_);
    }
}
{

    package KENTNL::Top;

    sub top_function {
# line 3000
        KENTNL::Child::child_function(@_);
    }
}

