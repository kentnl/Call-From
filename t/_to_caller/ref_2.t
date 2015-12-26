use strict;
use warnings;

use Test::More;

# ABSTRACT: Check _to_caller(['Name','file'])

use Call::From;

my $pkg  = 'KENTNL::Fake::Package';
my $file = 'bogus/file';
my $ref  = [ $pkg, $file ];

subtest "_to_caller([$pkg,$file],0)" => sub {
    note explain my $result = [ KENTNL::Top::top_function( $ref, 0 ) ];
    is( $result->[0], $pkg,  '0th frame package' );
    is( $result->[1], $file, '0th frame file' );
    is( $result->[2], 1000,  '0th frame line' );
};

subtest "_to_caller([$pkg,$file],1)" => sub {
    note explain my $result = [ KENTNL::Top::top_function( $ref, 1 ) ];
    is( $result->[0], $pkg,  '1th frame package' );
    is( $result->[1], $file, '1th frame file' );
    is( $result->[2], 2000,  '1th frame line' );
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

