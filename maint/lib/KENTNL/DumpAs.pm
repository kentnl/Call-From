use 5.006;    # our
use strict;
use warnings;

package KENTNL::DumpAs;

# ABSTRACT: Dump refs as code

use Exporter 5.57 qw( import );

our @EXPORT_OK = qw( dump_as );

sub dump_as {
    my ( $name, $ref ) = @_;
    require Data::Dumper;
    my $dumper = Data::Dumper->new( [$ref], [$name] );
    $dumper->Sortkeys(1);
    $dumper->Indent(1);
    $dumper->Useqq(1);
    return $dumper->Dump;
}

1;

