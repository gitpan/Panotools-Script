#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';
use File::Temp qw/ tempfile /;

use_ok ('Panotools::Script');

my $p = new Panotools::Script;
$p->Read ('t/data/cemetery/hugin-optimise.txt');

{
my ($fh, $tempfile) = tempfile (SUFFIX => '.txt', UNLINK => 1);
ok ($p->Write ($tempfile), "script written to $tempfile");
#`cp $tempfile /tmp/foo.txt`; die;
}

# set projection to Mercator
#$p->Panorama->{f} = '5';

ok ($p->Optimise, 'Optimisation succeeds');


