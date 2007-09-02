#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';
use File::Temp qw/ tempdir /;
use File::Spec;
my $tempdir = tempdir (CLEANUP => 1);

use_ok ('Panotools::Script');

my $p = new Panotools::Script;
$p->Read ('t/data/cemetery/hugin-stitch.txt');

{
my $tempfile = File::Spec->catfile ($tempdir, '010.txt');
ok ($p->Write ($tempfile), "script written to $tempfile");
}

# set Gamma correction to 2.2
$p->Mode->{g} = '2.2';

# set projection to Mercator
$p->Panorama->{f} = '5';

{
my $tempfile = File::Spec->catfile ($tempdir, '010-mercator.txt');
ok ($p->Write ($tempfile), "script written to $tempfile");
}

for my $stitcher ('nona')
{

$p->{stitcher} = $stitcher;

{
    my $image = File::Spec->catfile ($tempdir, '010-uncompressed.tif');
    $p->Panorama->{n} = '"TIFF c:NONE"';
    ok ($p->Stitch ($image), "$stitcher stitched uncompressed file");
    like ((stat($image))[7], '/^1[12][0-9]{5}$/', "$stitcher uncompressed size is about 1.2MiB");
}

#{
#    my ($fh, $image) = tempfile (SUFFIX => '.tif', UNLINK => 1);
#    $p->Panorama->{n} = '"TIFF c:LZW"';
#    ok ($p->Stitch ($image), "$stitcher stitched LZW compressed file");
#    like ((stat($image))[7], '/^[567][0-9]{5}$/', "$stitcher LZW compressed size is about 5-700kB");
#}

{
    my $image = File::Spec->catfile ($tempdir, '010-deflate.tif');
    $p->Panorama->{n} = '"TIFF c:DEFLATE"';
    ok ($p->Stitch ($image), "$stitcher stitched DEFLATE compressed file");
    like ((stat($image))[7], '/^[567][0-9]{5}$/', "$stitcher DEFLATE compressed size is about 5-700kB");
}

}

#ok ($p->Optimise == 0, 'optimisation fails because of no control points');


