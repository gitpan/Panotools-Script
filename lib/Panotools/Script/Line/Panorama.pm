package Panotools::Script::Line::Panorama;

use strict;
use warnings;
use Panotools::Script::Line;

=head1 NAME

Panotools::Script::Line::Panorama - Panotools panorama parameters

=head1 SYNOPSIS

Panorama parameters are described by a 'p' line

=head1 DESCRIPTION

  w1000        width in pixels
  h600         height in pixels
  f0           projection format,
                   0 - rectilinear (for printing and viewing)
                   1 - Cylindrical (for Printing and QTVR)
                   2 - Equirectangular ( for Spherical panos), default
                   3 - full-frame fisheye
  v360         horizontal field of view of panorama (default 360)
  nPICT        Panorama file format, one of:
                   PNG           png-format, 8 & 16 bit supported
                   TIFF          tiff-format, all tiff types supported (8,16,32 bit int, float, double)
                   TIFF_m        tiff-format, multi-file, one image per file
                                   alpha layer with non-feathered clip mask at image border
                   TIFF_multilayer  tiff-format, multi-image-file, all files in one image
                                   alpha layer with non-feathered clip mask at image border
                                   This filetype is supported by The GIMP
                   JPEG          Panoramic image in jpeg-format.
                some more supported file formats (mostly only 8 bit support)
                   PNM, PGM, BMP, SUN, VIFF
 
               Special options for TIFF output:
               n"TIFF c:NONE"
                   c - select TIFF compression, possible options: NONE, LZW, DEFLATE
 
               Special options for TIFF_m and TIFF_multilayer output:
               n"TIFF c:NONE r:CROP"
                   c - TIFF compression, possible options NONE, LZW, DEFLATE
                   r - output only used image area (cropped output). The crop offsets
                       are stored in the POSITIONX and POSITONY tiff tags
                   p1 - save coordinate images (useful for further programs, like vignetting correction)
 
               Special options for JPEG output:
               n"JPEG q95"
                   q - jpeg quality

  u10          width of feather for stitching all images. default:10
  k1           attempt color & brightness correction using image number as anchor
  b1           attempt brightness correction with no color change using image number as anchor
  d1           attempt color correction with no brightness change using image number as anchor
                   Do not use more than one of k, d, b.This is new method of correcting

  E1           exposure value for final panorama
  R1           stitching mode: 0: normal LDR mode, 1: HDR mode
  T"UINT8"     bitdepth of output images, possible values are
               UINT8  -  8 bit unsigned
               UINT16 - 16 bit unsigned
               FLOAT  - 32 bit floating point
               By default the bit depth of the input images is used.

=cut

use vars qw /@ISA/;
@ISA = qw /Panotools::Script::Line/;

sub _defaults
{
    my $self = shift;
    $self->{w} = "1000";
    $self->{h} = "500";
    $self->{v} = "360.0";
    $self->{n} = "JPEG";
    $self->{E} = "0";
    $self->{f} = "2";
}

sub _valid { '^([bdfhknuvwERT])(.*)' }

sub Identifier
{
    my $self = shift;
    return "p";
}

1;
