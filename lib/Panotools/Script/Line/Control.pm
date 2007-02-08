package Panotools::Script::Line::Control;

use strict;
use warnings;
use Panotools::Script::Line;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

=head1 NAME

Panotools::Script::Line::Control - Panotools control-point

=head1 SYNOPSIS

A pair of control-points forms a 'c' line

=head1 DESCRIPTION

One line per point pair.
about one pair of points per image per variable being optimized.
The more variables being optimized the more control points needed.

  n0           first image
  N1           second image
  x1066.5      first image x point position
  y844.333     first image y point position
  X239.52      second image x point position
  Y804.64      second image y point position
  t0           type of control point (optional)
                 0 - normal (default)
                 1 - optimize horizontally only
                 2 - optimize vertically only
                 3+ (all other numbers) - straight line

=cut

sub _defaults
{
    my $self = shift;
}

sub _valid { return '^([nNxXyYt])(.*)' }

sub Identifier
{
    my $self = shift;
    return "c";
}

1;

