package Panotools::Matrix;

=head1 NAME

Panotools::Matrix - Miscellaneous math for panoramic images

=head1 SYNOPSIS

$matrix = rollpitchyaw2matrix ($roll, $pitch, $yaw);

All angles are in radians not degrees.

=head1 DESCRIPTION

rollpitchyaw2matrix returns a Math::Matrix object that encapsulates a
transformation suitable for rotating a vector/point by three degrees of freedom
(roll, pitch and yaw).

roll is positive rotation around the x-axis

pitch is negative rotation around the y-axis

yaw is negative rotation around the z axis

=head1 USAGE

use Math::Matrix;

use Panotools::Matrix;

my $point  = new Math::Matrix ([$x1], [$y1], [$z1]);

my $matrix = rollpitchyaw2matrix ($roll, $pitch, $yaw);

my $result = $matrix->multiply ($point);

($x2, $y2, $z2) = ($result->[0][0], $result->[1][0], $result->[2][0]);

=head1 FILES

Requires Math::Matrix as this is all matrix mathematics.

=head1 COPYRIGHT

Copyright (c) 2001 Bruno Postle <bruno@postle.net>. All Rights Reserved. This
module is Free Software. It may be used, redistributed and/or modified under
the same terms as Perl itself.

This module is partly based on Math::Geometry by Greg McCarroll
<greg@mccarroll.demon.co.uk>

=cut

use Math::Matrix;
use Math::Trig;
use Math::Trig ':radial';
use strict;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(rollpitchyaw2matrix matrix2rollpitchyaw); 

sub rollpitchyaw2matrix {
    my ($roll, $pitch, $yaw) = @_;

    my $cosr = cos ($roll);
    my $sinr = sin ($roll);
    my $cosp = cos ($pitch);
    my $sinp = sin (0 - $pitch);
    my $cosy = cos ($yaw);
    my $siny = sin (0 - $yaw);

    my $rollm  = new Math::Matrix ([        1,       0,       0 ],
                                   [        0,   $cosr,-1*$sinr ],
                                   [        0,   $sinr,   $cosr ]);

    my $pitchm = new Math::Matrix ([    $cosp,       0,   $sinp ],
                                   [        0,       1,       0 ],
                                   [ -1*$sinp,       0,   $cosp ]);

    my $yawm   = new Math::Matrix ([    $cosy,-1*$siny,       0 ],
                                   [    $siny,   $cosy,       0 ],
                                   [        0,       0,       1 ]);

    $yawm->multiply ($pitchm)->multiply ($rollm);
}

# following copied from a spreadsheet by Stuart Milne

sub matrix2rollpitchyaw
{
    my $matrix = shift;
    my $roll = atan2 ($matrix->[2]->[1], $matrix->[2]->[2]);
    my $pitch = -1 * asin (-1 * $matrix->[2]->[0]);
    my $yaw = atan2 (-1 * $matrix->[1]->[0], $matrix->[0]->[0]);
    return ($roll, $pitch, $yaw);
}

1;

