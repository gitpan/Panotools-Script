#!/usr/bin/perl

# Requires p2e from App::Packer

# Par::Packer might work better:
# http://par.wikia.com/wiki/Main_Page

my @stubs = qw/
cubic2erect
enblend-mask
enblend-svg
erect2cubic
erect2mercator
erect2planet
erect2qtvr
jpeg2qtvr
match-n-shift
nona-mask
pafextract
panostart
process-masks
pto2fulla
pto2tiff
ptocentre
ptoclean
ptoget
ptograph
ptoinfo
ptomerge
ptopath
ptoset
ptosort
ptosplit
qtvr2erect
tif2svg
transform-pano/;

for my $stub (@stubs)
{
    system ('copy', "bin\\$stub", "$stub.pl");
    system ('p2e', '--add-module=Win32', '--add-module=File::Spec::Win32', "--output-file=$stub.exe", "$stub.pl"); 
    unlink ("$stub.pl");
}
