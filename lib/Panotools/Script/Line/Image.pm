package Panotools::Script::Line::Image;

use strict;
use warnings;
use Panotools::Script::Line;

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

=head1 NAME

Panotools::Script::Line::Image - Panotools input image

=head1 SYNOPSIS

A single input image is described by an 'i' line

=head1 DESCRIPTION

Basically the same format as an 'o' line.

  w1000
  h500     nona requires the width and height of input images wheras PTStitcher/mender don't

  f0           projection format,
                   0 - rectilinear (normal lenses)
                   1 - Panoramic (Scanning cameras like Noblex)
                   2 - Circular fisheye
                   3 - full-frame fisheye
                   4 - PSphere, equirectangular
  v82          horizontal field of view of image (required)
  y0           yaw angle (required)
  p43          pitch angle (required)
  r0           roll angle (required)
  a,b,c        lens correction coefficients (optional)
                   (see http://www.fh-furtwangen.de/~dersch/barrel/barrel.html)
  d,e          initial lens offset in pixels(defaults d0 e0, optional).
                   Used to correct for offset from center of image
                   d - horizontal offset,
                   e - vertical offset
  g,t          initial lens shear.  Use to remove slight misalignment
                   of the line scanner relative to the film transport
                   g - horizontal shear
                   t - vertical shear
 
  K0a, K0b     linear color/grayvalue correction coefficients for each channel
  K1a, K1b        (for grayscale images Only K0a, K0b is used):
  K2a, K2b        i_red = K0a * i_red + K0b
                  i_green = K1a * i_green + K1b
                  i_blue = K2a * i_blue + K2b
                This correction is applied after the flatfield flatfield correction.
 
  Eev          exposure of image in EV (exposure values)
  Er           white balance factor for red channel
  Eb           white balance factor for blue channel

  Ra           EMoR response model from the Computer Vision Lab at Columbia University
  Rb           This models the camera response curve
  Rc
  Rd
  Re

  Vm           vignetting correction mode (default 0):
                   0: no vignetting correction
                   1: radial vignetting correction (see j,k,l,o options)
                   2: flatfield vignetting correction (see p option)
                   4: proportional correction: i_new = i / corr.
                        This mode is recommended for use with linear data.
                        If the input data is gamma corrected, try adding g2.2
                        to the m line.
 
                       default is additive correction: i_new = i + corr

                     Both radial and flatfield correction can be combined with the
                      proportional correction by adding 4.
                  Examples: i1 - radial polynomial correction by addition.
                                  The coefficients j,k,l,o must be specified.
                            i5 - radial polynomial correction by division.
                                  The coefficients j,k,l,o must be specified.
                            i6 - flatfield correction by division.
                                  The flatfield image should be specified with the p option
 
  Va,Vb,Vc,Vd  vignetting correction coefficients. (defaults: 0,0,0,0)
                ( 0, 2, 4, 6 order polynomial coefficients):
                 corr = ( i + j*r^2 + k*r^4 + l*r^6), where r is the distance from the image center
               The corrected pixel value is calculated with: i_new = i_old + corr
               if additive correction is used (default)
 			   for proportional correction (h5): i_new = i_old / corr;
 
  Vx,Vy        radial vignetting correction offset in pixels (defaults q0 w0, optional).
                  Used to correct for offset from center of image
                   Vx - horizontal offset
                   Vy - vertical offset
 
  Vf           filename of flatfield image.
                For additive correction the image will be used as it is.
                In the case of correction by division, the flatfield will be divided by
                its mean value.
 
 
  S100,600,100,800   Selection(l,r,t,b), Only pixels inside the rectangle will be used for conversion.
                        Original image size is used for all image parameters
                        (e.g. field-of-view) refer to the original image.
                        Selection can be outside image dimension.
                        The selection will be circular for circular fisheye images, and
                        rectangular for all other projection formats

  X10          World coordinates of camera position, only used for PTStereo
  Y200         If the camera is aligned (yaw = pitch = roll = 0.0),
  Z-13.5       X is coordinate to the right, Y vertically up and
               -Z is forward viewing direction.
  nName        file name of the input image.

  C100,600,100,800   Crop(l,r,t,b), Only pixels inside the rectangle will be used for conversion.
                        Cropped image size is used for all image parameters
                        (e.g. field-of-view) refer to the cropped part of the image.

  i            (the small letter). Morph-to-fit using control points.

  i f2 r0   p0    y0     v183    a0 b-0.1 c0  S100,600,100,800 n"photo1.jpg"
  i f2 r0   p0    y180   v183    a0 b-0.1 c0  S100,600,100,800 n"photo1.jpg"

=cut

sub _defaults
{
    my $self = shift;
}

sub _valid { return '^([abcdefghnprtvwy]|[SCXYZ]|K[0-2][ab]|V[abcdfmxy]|Eev|E[rb]|R[abcde])(.*)' }

sub _valid_ptoptimizer { return '^([abcdefghnprtvwySC])(.*)' }

sub _sanitise_ptoptimizer
{
    my $self = shift;
    my $valid = $self->_valid_ptoptimizer;
    for my $key (keys %{$self})
    {
        delete $self->{$key} unless (grep /$valid/, $key);
    }
}

sub Identifier
{
    my $self = shift;
    return "i";
}

sub Assemble
{
    my $self = shift;
    my $vector = shift || '';
    $self->_sanitise;
    my @tokens;
    for my $entry (sort keys %{$self})
    {
        my $value = $self->{$entry};
        $value = _prepend ($vector, $value) if ($entry eq 'n');
        push @tokens, $entry . $value;
    }
    return (join ' ', ($self->Identifier, @tokens)) ."\n" if (@tokens);
}

sub _prepend
{
    my $vector = shift;
    my $name = shift;
    return $name unless $vector;
    $name =~ s/^"//;
    $name =~ s/"$//;
    use File::Spec;
    unless (File::Spec->file_name_is_absolute ($name))
    {
        $name = File::Spec->catfile ($vector, $name);
    }
    return "\"$name\"";
}

1;

