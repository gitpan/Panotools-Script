package Panotools::Script::Line::ControlMorph;

use strict;
use warnings;
use Panotools::Script::Line;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

=head1 NAME

Panotools::Script::Line::ControlMorph - Panotools morph control-point

=head1 SYNOPSIS

A single morph control-point forms a 'C' line

=head1 DESCRIPTION

Morphing of control point lines
One line per point
Created automatically by optimizer

  i0           image
  x363.726     starting x point position
  y125.738     starting y point position
  X363.838     morphed x point position
  Y125.618     morphed y point position

  C i0  x363.726 y125.738 X363.838 Y125.618

=cut

sub _defaults
{
    my $self = shift;
}

sub _valid { return '^([ixXyY])(.*)' }

sub Identifier
{
    my $self = shift;
    return "C";
}

1;

