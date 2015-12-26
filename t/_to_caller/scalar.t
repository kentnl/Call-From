use strict;
use warnings;

use Test::More;

# ABSTRACT: Check _to_caller behaviour with explicit package names

use Call::From;

sub __file { [caller]->[1] }

my $pkg = 'KENTNL::Fake::Package';

subtest "_to_caller(<name>,0)" => sub {
    note explain my $result = [ KENTNL::Top::top_function( $pkg, 0 ) ];
    is( $result->[0], $pkg,   '0th frame package' );
    is( $result->[1], __file, '0th frame file' );
    is( $result->[2], 1000,   '0th frame line' );
};

subtest "_to_caller(<name>,1)" => sub {
    note explain my $result = [ KENTNL::Top::top_function( $pkg, 1 ) ];
    is( $result->[0], $pkg,   '1th frame package' );
    is( $result->[1], __file, '1th frame file' );
    is( $result->[2], 2000,   '1th frame line' );
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

