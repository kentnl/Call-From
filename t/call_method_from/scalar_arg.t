use strict;
use warnings;

use Test::More;

# ABSTRACT: Check call_method_from behaviour

{

    package KENTNL::Dud;

    sub a_method {
        my ( $self, @args ) = @_;
        my (@call) = caller();
        return {
            self   => $self,
            args   => \@args,
            caller => [ @call[ 0 .. 2 ] ],
        };
    }
}
{

    package KENTNL::Proxy;

    use Call::From qw( call_method_from );

    sub do_work {
        my ( $self, @args ) = @_;
#line 30
        return KENTNL::Dud->${ \call_method_from('KENTNL::Pretend') }
          ( 'a_method', @args );
    }
}

SKIP: {
    my $result = KENTNL::Proxy->do_work(qw( hello world ));
    note "return context is expected {";
    note explain $result;
    is( ref $result, 'HASH', "Got the hash back the method passed" )
      or skip "Can't compare HASH", 3;

    subtest "->{args}" => sub {
      SKIP: {
            ok( exists $result->{args}, "args exists" )
              or skip "Can't compare args", 2;

            for ( $result->{args} ) {

                is( ref, "ARRAY", "args is an array" )
                  or skip "Not an array", 1;

                is_deeply( $_, [qw( hello world )], "List passed through" );
            }
        }
    };
    subtest "->{caller}" => sub {
      SKIP: {
            ok( exists $result->{caller}, "caller exists" )
              or skip "Can't compare caller", 4;

            my $context = $result->{caller};
            is( ref $context, "ARRAY", "caller is an array" )
              or skip "Not an array", 3;

            is( $context->[0], 'KENTNL::Pretend', "Spoofed namespace exists" );
            is(
                $context->[1],
                sub { [ caller(0) ]->[1] }
                  ->(), "Path passed through as-is"
            );
            is( $context->[2], '30', "line directive in proxy not overridden" );

        }
    };
    subtest '->{self}' => sub {
      SKIP: {
            ok( exists $result->{self}, "self exists" )
              or skip "Can't compare self", 1;
            is( $result->{self}, 'KENTNL::Dud', 'Invocant passed through' );
        }
    };

}

done_testing;

