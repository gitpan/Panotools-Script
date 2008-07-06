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

=pod

Get a simplified description of a control point useful for identifying
duplicates like so:

  print $point->Packed;

Format is first image, x, y, second image, x, y, point type

e.g: 2,123,456,3,234,567,0

=cut

sub Packed
{
    my $self = shift;
    if ($self->{n} < $self->{N})
    {
        return join ',', $self->{n}, int ($self->{x}), int ($self->{y}),
                         $self->{N}, int ($self->{X}), int ($self->{Y}), $self->{t};
    }
    else
    {
        return join ',', $self->{N}, int ($self->{X}), int ($self->{Y}),
                         $self->{n}, int ($self->{x}), int ($self->{y}), $self->{t};
    }
}

1;

