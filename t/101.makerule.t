#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use File::Temp qw/tempdir/;
use File::Spec;
use lib 'lib';

use Panotools::Makefile::Rule;
for my $file ('foo',
'Westward Ho!',
'foo#bar',
'foo bar',
'fooübar',
'fooébar',
'foo°bar',
'foo&bar',
'foo!bar',
'foo,bar',
'foo_bar',
'foo.bar',
'foo-bar',
'foo{bar',
'foo}bar',
'foo+bar',
'foo@bar',
'foo[bar',
'foo]bar',
'foo`bar',
'foo~bar',
"foo'bar",
'foo(bar',
'foo)bar',
'foo$bar',
'$bar',
'bar$',
'#bar',
' bar',
'übar',
'ébar',
'°bar',
'&bar',
'!bar',
',bar',
'_bar',
'-bar',
'{bar',
'}bar',
'+bar',
'@bar',
'[bar',
']bar',
'`bar',
'~bar',
"'bar",
'(bar',
')bar',
'^bar',
'foo^bar',
"foo^'bar",
'foo^&bar',
'foo^ bar',
# filenames that will never work on Windows
'foo?bar',
'foo<bar',
'foo>bar',
'foo*bar',
'foo|bar',
'foo"bar'
)
{
    ok (testfilename ($file));
}

# Should be ok, but need different tests
#'foo/bar',
#'foo\bar',

# make syntax can't be used in filenames
#'foo$(FOO)bar',
#'foo${FOO}bar',
#'foo=bar',
#'foo%bar',
#'foo;bar',
#'foo:bar',
#'.bar',
#'%bar',

sub testfilename
{
    my $filename = shift;
    my $filename_out = $filename . '_out';

    my $rule = new Panotools::Makefile::Rule;

    $rule->Targets ($filename_out);
    $rule->Prerequisites ($filename);
    $rule->Command ('cp', '--', $filename, $filename_out);

    my $tempdir = tempdir (CLEANUP => 1);
    my $file = File::Spec->catfile ($tempdir, $filename);
    open FILE, ">", $file;
    close FILE;
    # no point proceeding if perl couldn't create the file
    return 1 unless -e $file;

    my $makefile = File::Spec->catfile ($tempdir, 'Makefile');
    open MAKE, ">", $makefile;
    print MAKE $rule->Assemble;
    close MAKE;
    chdir $tempdir;
    system ('make');
    return 1 if -e $filename_out;
    print $rule->Assemble;
    return 0;
}
