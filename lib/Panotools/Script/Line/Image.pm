package Panotools::Script::Line::Image;

use strict;
use warnings;
use Panotools::Script::Line;
use Panotools::Matrix qw(matrix2rollpitchyaw rollpitchyaw2matrix multiply);
use Math::Trig;
use Math::Trig ':radial';

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

  S100,600,100,800   Selection(l,r,t,b), Only pixels inside the rectangle will be used for conversion.
                        Original image size is used for all image parameters
                        (e.g. field-of-view) refer to the original image.
                        Selection can be outside image dimension.
                        The selection will be circular for circular fisheye images, and
                        rectangular for all other projection formats

  nName        file name of the input image.

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

=pod

Rotate transform the image, angles in degrees:

  $i->Transform ($roll, $pitch, $yaw);

=cut

sub Transform
{
    my $self = shift;
    my ($roll, $pitch, $yaw) = @_;
    my @transform_rpy = map (deg2rad ($_), ($roll, $pitch, $yaw));
    my $transform_matrix = rollpitchyaw2matrix (@transform_rpy);
    my @rpy = map (deg2rad ($_), ($self->{r}, $self->{p}, $self->{y}));
    my $matrix = rollpitchyaw2matrix (@rpy);
    my $result = multiply ($transform_matrix, $matrix);
    my ($r, $p, $y) = map (rad2deg ($_), matrix2rollpitchyaw ($result));
    $self->{r} = $r;
    $self->{p} = $p;
    $self->{y} = $y;
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

sub Report
{
    my $self = shift;
    my @report;

    my $format = 'UNKNOWN';
    $format = "Rectilinear" if $self->{f} == 0;
    $format = "Cylindrical" if $self->{f} == 1;
    $format = "Circular Fisheye" if $self->{f} == 2;
    $format = "Full-frame Fisheye" if $self->{f} == 3;
    $format = "Equirectangular" if $self->{f} == 4;

    push @report, ['Dimensions', $self->{w} .'x'. $self->{h}];
    push @report, ['Megapixels', int ($self->{w} * $self->{h} / 1024 / 1024 * 10) / 10];
    push @report, ['Format', $format];
    push @report, ['Horizontal Field of View', $self->{v}];
    push @report, ['Roll Pitch Yaw', $self->{r} .','. $self->{p} .','. $self->{y}];
    push @report, ['Lens distortion', $self->{a} .','. $self->{b} .','. $self->{c}] if defined $self->{a};
    push @report, ['Image centre', $self->{d} .','. $self->{e}] if defined $self->{d};
    push @report, ['Image shear', $self->{g} .','. $self->{t}] if defined $self->{g};
    push @report, ['Exposure Value', $self->{Eev}];
    push @report, ['Red Blue colour balance', $self->{Er} .','. $self->{Eb}];
    push @report, ['EMOR parameters', $self->{Ra} .','. $self->{Rb} .','. $self->{Rc} .','. $self->{Rd} .','. $self->{Re}];
    push @report, ['Vignetting parameters', $self->{Va} .','. $self->{Vb} .','. $self->{Vc} .','. $self->{Vd}];
    push @report, ['Vignetting centre', $self->{Vx} .','. $self->{Vy}];
    push @report, ['Selection area', $self->{S}] if defined $self->{S};
    push @report, ['File name', $self->{n}];

    [@report];
}

sub W2
{
    my $self = shift;
    return ($self->{w} / 2) if ($self->{w} < $self->{h});
    return ($self->{h} / 2);
}

sub V
{
    my $self = shift;
    my $pto = shift;
    if ($self->{v} =~ /^=([0-9]+)$/) {return $pto->Image->[$1]->{v}};
    return $self->{v};
}

sub A
{
    my $self = shift;
    my $pto = shift;
    return 0.0 unless defined ($self->{a});
    if ($self->{a} =~ /^=([0-9]+)$/) {return $pto->Image->[$1]->{a}};
    return $self->{a};
}

sub B
{
    my $self = shift;
    my $pto = shift;
    return 0.0 unless defined ($self->{b});
    if ($self->{b} =~ /^=([0-9]+)$/) {return $pto->Image->[$1]->{b}};
    return $self->{b};
}

sub C
{
    my $self = shift;
    my $pto = shift;
    return 0.0 unless defined ($self->{c});
    if ($self->{c} =~ /^=([0-9]+)$/) {return $pto->Image->[$1]->{c}};
    return $self->{c};
}

sub D
{
    my $self = shift;
    my $pto = shift;
    return 0.0 unless defined ($self->{d});
    if ($self->{d} =~ /^=([0-9]+)$/) {return $pto->Image->[$1]->{d}};
    return $self->{d};
}

sub E
{
    my $self = shift;
    my $pto = shift;
    return 0.0 unless defined ($self->{e});
    if ($self->{e} =~ /^=([0-9]+)$/) {return $pto->Image->[$1]->{e}};
    return $self->{e};
}

# copied from libpano12 math.c inverse polynomial using Newton's method
sub _inv_radial
{
    my $self = shift;
    my $pto = shift;
    my $dest = shift;
    my $a = $self->A ($pto);
    my $b = $self->B ($pto);
    my $c = $self->C ($pto);
    my $d = 1 - $a - $b - $c;

    my $iter = 0;
    my $MAXITER = 100;
    my $R_EPS = 0.000001;

    my $rd = (sqrt ($dest->[0] * $dest->[0] + $dest->[1] * $dest->[1])) / $self->W2;

    return [0, 0] if $rd == 0;

    my $rs = $rd;
    my $f = ((($a * $rs + $b) * $rs + $c) * $rs + $d) * $rs;

    while (abs ($f - $rd) > $R_EPS && $iter < $MAXITER)
    {
        $rs = $rs - ($f - $rd) / (((4 * $a * $rs + 3 * $b) * $rs + 2 * $c) * $rs + $d);
        $f = ((($a * $rs + $b) * $rs + $c) * $rs + $d) * $rs;
        $iter++;
    }

    my $scale = $rs / $rd;
    # print "scale = $scale iter = $iter\n";

    return [$dest->[0] * $scale, $dest->[1] * $scale];
}

sub _radial
{
    my $self = shift;
    my $pto = shift;
    my $dest = shift;
    my $a = $self->A ($pto);
    my $b = $self->B ($pto);
    my $c = $self->C ($pto);
    my $d = 1 - $a - $b - $c;

    my $r = (sqrt ($dest->[0] * $dest->[0] + $dest->[1] * $dest->[1])) / $self->W2;
    my $scale = (($a * $r + $b) * $r + $c) * $r + $d;

    return [$dest->[0] * $scale, $dest->[1] * $scale];
}

=pod

For any given coordinate in this image (top left is 0,0), calculate an x,y,z
cartesian coordinate, accounting for lens distortion, projection and rotation.

=cut

sub To_Cartesian
{
    my $self = shift;
    my $pto = shift;
    my $pix = shift;

    $pix->[0] = ($self->{w}/2) - $pix->[0] + $self->D ($pto);
    $pix->[1] = ($self->{h}/2) - $pix->[1] + $self->E ($pto);
    $pix = $self->_inv_radial ($pto, $pix);

    # FIXME returns false value for cylindrical and equirectangular images
    my $point = [[1],[0],[0]];

    if ($self->{f} == 0)
    {
        my $rad = ($self->{w}/2) / tan (deg2rad ($self->V ($pto)) / 2);
        $point = [[$rad], [$pix->[0]], [$pix->[1]]];
    }
    if ($self->{f} == 2 or $self->{f} == 3)
    {
        my ($rho, $theta, $z) = cartesian_to_cylindrical ($pix->[1], $pix->[0], 1);
        my $phi = $rho * deg2rad ($self->V ($pto)) / $self->{w};
        $rho = $z;

        ($point->[2]->[0],
         $point->[1]->[0],
         $point->[0]->[0])
         = spherical_to_cartesian ($rho, $theta, $phi);
    }

    my $matrix = rollpitchyaw2matrix
                   (deg2rad ($self->{r}), deg2rad ($self->{p}), deg2rad ($self->{y}));

    multiply ($matrix, $point);
}

1;

