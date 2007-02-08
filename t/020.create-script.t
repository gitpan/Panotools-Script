#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';
use File::Temp qw/ tempfile /;

use_ok ('Panotools::Script');

my $p = new Panotools::Script;

{
my ($fh, $tempfile) = tempfile (SUFFIX => '.txt', UNLINK => 1);
ok ($p->Write ($tempfile), "script written to $tempfile");
}
# set Gamma correction to 2.2
$p->{mode}->{g} = '2.2';

# set projection to Mercator
$p->{panorama}->{f} = '5';

{
    my $image = new Panotools::Script::Line::Image;
    $image->Set (w => 640, h => 480,
                 f => 0,
                 z => 'bogus',
                 v => 50,
                 y => 0, p => 0, r => 0,
                 n => '"somefile.jpg"');
    push @{$p->{image}}, $image;
}

{
    my $image = new Panotools::Script::Line::Image;
    $image->Set (w => 640, h => 480,
                 f => 0,
                 z => 'bogus',
                 v => '=0',
                 y => 40, p => 0, r => 0,
                 n => '"someotherfile.jpg"');
    push @{$p->{image}}, $image;
}

{
my ($fh, $tempfile) = tempfile (SUFFIX => '.txt', UNLINK => 1);
ok ($p->Write ($tempfile), "script written to $tempfile");
}

ok (@{$p->{output}} == 0, 'no o lines yet');
$p->Image2Output;
ok (@{$p->{output}} == 2, 'two o lines after Image2Output()');

ok ($p->{output}->[1]->{v} == 50, 'second image inherits fov from first');

$p->{output}->[0]->{v} = 40;
$p->{output}->[1]->{v} = 30;

$p->Output2Image;

ok ($p->{image}->[0]->{v} == 40, 'fov propogates back to first image');
ok ($p->{image}->[1]->{v} eq '=0', 'fov doesn\'t propogate back to second image');

$p->Image2Output;

ok ($p->{output}->[1]->{v} == 40, 'second image inherits fov from first');

ok ($p->{output}->[0]->{n} eq '"somefile.jpg"', 'filename reverts');
ok ($p->{output}->[1]->{n} eq '"someotherfile.jpg"', 'filename reverts');

#use Data::Dumper; warn Dumper $p;


