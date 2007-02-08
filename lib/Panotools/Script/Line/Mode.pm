package Panotools::Script::Line::Mode;

use strict;
use warnings;
use Panotools::Script::Line;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

=head1 NAME

Panotools::Script::Line::Mode - Panotools stitching mode

=head1 SYNOPSIS

Optional stitching modes are described by an 'm' line

=head1 DESCRIPTION

  m i2

  g2.5         Set gamma value for internal computations (default 1.0)
                   See <http://www.fh-furtwangen.de/~dersch/gamma/gamma.html>
                This is especially useful in conjunction with the vignetting correction
                by division
 

  i2           Set interpolator, See <http://www.fh-furtwangen.de/~dersch/interpolator/interpolator.html>
                 one of:
                    0 - poly3 (default)
                    1 - spline16,
                    2 - spline36,
                    3 - sinc256,
                    4 - spline64,
                    5 - bilinear,
                    6 - nearest neighbor,
                    7 - sinc1024
 

                    8 - Box
                    9 - Bartlett/Triangle
                    10 - Hermite
                    11 - Hanning
                    12 - Hamming
                    13 - Blackmann
                    14 - Gaussian 1/sqrt(2)
                    15 - Gaussian 1/2
                    16 - Quadardic
                    17 - Cubic
                    18 - Catmull-Rom
                    19 - Mitchell
                    20 - Lanczos2
                    21 - Lanczos3
                    22 - Blackman/Bessel
                    23 - Blackman/sinc
                    
  f0		   Invoke Faster Transformation also invoked by creating a file named "pano12_opt.txt" 
                    in the same foler as project with a line FAST_TRANSFORM

  p0           Create panorama after optimizing control points
                   0 no(default), 1 yes

=cut

sub _defaults
{
    my $self = shift;
    $self->{g} = "1.0";
    $self->{i} = "0";
}

sub _valid { return '^([fgip])(.*)' }

sub Identifier
{
    my $self = shift;
    return "m";
}

1;
