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
        my ( $self, $frame, @args ) = @_;
#line 31
        return KENTNL::Dud->${ \call_method_from($frame) }( 'a_method', @args );
    }

    sub do_work_2 {
#line 36
        return __PACKAGE__->do_work( @_[ 1 .. $#_ ] );
    }
}

sub __file() { [caller]->[1] }

my @frames = (
    [ 'KENTNL::Proxy', __file, 31 ],    #
    [ 'KENTNL::Proxy', __file, 36 ],    #
    [ 'main',          __file, 52 ],    #
);

for my $frame ( 0, 1, 2 ) {
    subtest "call_method_from($frame)" => sub {
      SKIP: {
#line 52
            my $result = KENTNL::Proxy->do_work_2( $frame, qw( hello world ) );
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

                        is_deeply( $_, [qw( hello world )],
                            "List passed through" );
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

                    is(
                        $context->[0],
                        $frames[$frame]->[0],
                        "Spoofed namespace exists"
                    );
                    is(
                        $context->[1],
                        $frames[$frame]->[1],
                        "Path passed through as-is"
                    );
                    is(
                        $context->[2],
                        $frames[$frame]->[2],
                        "line directive in proxy not overridden"
                    );

                }
            };
            subtest '->{self}' => sub {
              SKIP: {
                    ok( exists $result->{self}, "self exists" )
                      or skip "Can't compare self", 1;
                    is( $result->{self}, 'KENTNL::Dud',
                        'Invocant passed through' );
                }
            };

        }
      }
}
done_testing;

