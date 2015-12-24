use 5.006;    # our
use strict;
use warnings;

package KENTNL::TestDirs;

# ABSTRACT: Return a list of .pm files that are install targets

use Path::Iterator::Rule;
use Exporter 5.57 qw( import );

our @EXPORT_OK = qw( test_dirs test_files );

my $rule = Path::Iterator::Rule->new();
$rule->file;
$rule->name(qr/.*\.t$/);

sub test_files {
    return $rule->all( $_[0] || './t' );
}

sub test_dirs {
    my %test_dirs;
    for my $file ( test_files( $_[0] ) ) {
        $file =~ s{/[^/]+\.t\z}{};
        $test_dirs{$file} = 1;
    }
    return keys %test_dirs;
}

1;

