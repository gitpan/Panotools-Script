package Panotools::Script::Line::Variable;

use strict;
use warnings;
use Panotools::Script::Line;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

=head1 NAME

Panotools::Script::Line::Variable - Panotools optimisation variables

=head1 SYNOPSIS

One or more parameters for optimisation form a 'v' line

=head1 DESCRIPTION

  Please note: the 'v'-line must come after the the 'i'-lines.
  Optimization variables are listed together with the image number
  starting at 0. There can be several v-lines.
 
  y0           Optimize yaw in image 0
  p1           Optimize pitch in image 1
  r2           Optimize roll in image 2
  v0           Optimize field of view in image 0
  a2           Optimize lens correction parameter 'a' in image 2
  b1
  c1
  d1
  e1
  g1
  t1

                   b and c can be equally optimized.
  X1           Optimize x-coordinate of image 1, only for PTStereo
  Y2           Optimize y-coordinate of image 2, only for PTStereo
  Z6           Optimize z-coordinate of image 6, only for PTStereo
 
       If a image has a parameter linked to another image only
       need to optimize the master.

=cut

sub _valid { return '^([abcdegprtvyXYZ])(.*)' }

sub Identifier
{
    my $self = shift;
    return "v";
}

sub Parse
{
    my $self = shift;
    my $string = shift || return 0;
    my $valid = $self->_valid;
    my @res = $string =~ / ([a-z][0-9]+)/g;
    for my $token (grep { defined $_ } @res)
    {
        my ($param, $image) = $token =~ /([a-z])([0-9]+)/;
        next unless defined $image;
        $self->{$image}->{$param} = 1;
    }
    $self->_sanitise;
    return 1;
}

sub Assemble
{
    my $self = shift;
    $self->_sanitise;
    my $string = '';
    for my $image (sort {$a <=> $b} (keys %{$self}))
    {
        my @tokens;
        for my $param (sort keys %{$self->{$image}})
        {
            push @tokens, $param . $image;
        }
        $string .= (join ' ', ($self->Identifier, @tokens)) ."\n";
    }
    return $string;
}

sub _sanitise
{
    my $self = shift;
    for my $image (keys %{$self})
    {
        delete $self->{$image} unless $image =~ /[0-9]+/;
    }
}

sub Report
{
    my $self = shift;
    my $index = shift;
    my @report;

    push @report, 'Roll' if $self->{$index}->{r};
    push @report, 'Pitch' if $self->{$index}->{p};
    push @report, 'Yaw' if $self->{$index}->{y};
    push @report, 'Field of View' if $self->{$index}->{v};
    push @report, 'a' if $self->{$index}->{a};
    push @report, 'b' if $self->{$index}->{b};
    push @report, 'c' if $self->{$index}->{c};
    push @report, 'd' if $self->{$index}->{d};
    push @report, 'e' if $self->{$index}->{e};
    push @report, 'g' if $self->{$index}->{g};
    push @report, 't' if $self->{$index}->{t};

    [[('Optimise parameters', (join ',', @report))]];
}

1;
