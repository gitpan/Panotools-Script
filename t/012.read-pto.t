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
$p->Read ('t/data/cemetery/hugin.pto');

$p->Transform (10,20,30);

like ($p->Image->[0]->{r}, '/-3.8642696077/');
like ($p->Image->[0]->{y}, '/-7.517201107/');
like ($p->Image->[0]->{p}, '/21.94771605/');

{
my $tempfile = File::Spec->catfile ($tempdir, '012.txt');
ok ($p->Write ($tempfile), "script written to $tempfile");
}

