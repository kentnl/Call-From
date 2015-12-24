use 5.006;
use strict;
use warnings;

package KENTNL::Abstracts;

# ABSTRACT: Extract an ABSTRACT from a pm file

use Exporter 5.57 qw( import );

our @EXPORT_OK = qw( abstract_from_file );

use Pod::Eventual 0.091480;
use parent qw(Pod::Eventual);    # better nonpod/blank events
use Path::Tiny qw( path );
use Carp qw( croak );

sub new {
    bless {} => shift;
}

sub handle_nonpod {
    my ( $self, $event ) = @_;
    return if $self->{abstract};
    return $self->{abstract} = $1
      if $event->{content} =~ /^\s*#+\s*ABSTRACT:[ \t]*(\S.*)$/m;
    return;
}

sub handle_event {
    my ( $self, $event ) = @_;
    return if $self->{abstract};
    if (   !$self->{in_name}
        and $event->{type} eq 'command'
        and $event->{command} eq 'head1'
        and $event->{content} =~ /^NAME\b/ )
    {
        $self->{in_name} = 1;
        return;
    }

    return unless $self->{in_name};

    if (    $event->{type} eq 'text'
        and $event->{content} =~ /^(?:\S+\s+)+?-+\s+(.+)\n$/s )
    {
        $self->{abstract} = $1;
        $self->{abstract} =~ s/\s+/\x20/g;
    }
}

sub abstract_from_file {
    my ($path) = @_;
    my $e      = __PACKAGE__->new;
    my $bytes  = path($path)->slurp_raw;
    $e->read_string($bytes);
    return $e->{abstract} if $e->{abstract};
    croak("Can't determine ABSTRACT from $path");
}

1;
