#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';
use File::Temp qw/ tempfile /;

use_ok ('Panotools::Script');

my $p = new Panotools::Script;
$p->Read ('t/data/cemetery/hugin.pto');

{
my ($fh, $tempfile) = tempfile (SUFFIX => '.txt', UNLINK => 1);
ok ($p->Write ($tempfile), "script written to $tempfile");
}

TODO: {
local $TODO = 'PTOptimizer doesn\'t like Va0 Vb0 in image lines';

ok ($p->Optimise, 'Optimisation succeeds');

}

# set projection to Mercator
$p->{panorama}->{f} = '5';

ok ($p->Optimise == 0, 'Optimisation fails');
