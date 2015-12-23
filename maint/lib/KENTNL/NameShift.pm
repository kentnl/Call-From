use 5.006;    # our
use strict;
use warnings;

package KENTNL::NameShift;

# ABSTRACT: Shape Distname / Module names between each other

# AUTHORITY

use Exporter 5.57 qw( import );

our @EXPORT_OK = qw( module_to_distname distname_to_module path_to_module module_to_path );

sub module_to_distname {
  my ( $module ) = @_;
  $module =~ s/::/-/g;
  return $module;
}

sub distname_to_module {
  my ( $distname ) = @_;
  $distname =~ s/-/::/g;
  return $distname;
}

sub module_to_path {
  my ( $module, $prefix ) = @_;
  $prefix =~ s/\/?$//;
  $module =~ s/::/\//g;
  return "$prefix/$module\.pm"
}
sub path_to_module {
  my ( $path, $prefix ) = @_;
  $prefix =~ s/\/?$//;
  $path =~ s/^\Q$prefix\E\///;
  $path =~ s/\//::/g;
  $path =~ s/\.pm$//;
  return $path;
}

1;

