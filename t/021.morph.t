#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';
use File::Temp qw/ tempfile /;

use_ok ('Panotools::Script');

my $p = new Panotools::Script;

# set projection to cylindrical
$p->Panorama->Set (f => 1, w => 600, h => 600, n => 'JPEG');

{
    $p->Image->[0] = new Panotools::Script::Line::Image;
    $p->Image->[0]->Set (w => 600, h => 300,
                           f => 4,
                           v => 360,
                           y => 180, p => 0, r => 0,
                           n => '"t/data/equirectangular/equirectangular.jpg"');
}

{
my ($fh, $tempfile) = tempfile (SUFFIX => '.txt', UNLINK => 0);
ok ($p->Write ($tempfile), "script written to $tempfile");
}

$p->Stitch ('/tmp/foo.jpg');

