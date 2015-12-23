use 5.006;    # our
use strict;
use warnings;

package KENTNL::PMFiles;

# ABSTRACT: Return a list of .pm files that are install targets

use Path::Iterator::Rule;
use Exporter 5.57 qw( import );

our @EXPORT_OK = qw( pm_files );

my $rule = Path::Iterator::Rule->new();
$rule->file;
$rule->name(qr/.*\.pm$/);

sub pm_files {
  return $rule->all( $_[0] || './lib' );
}
1;

