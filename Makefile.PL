use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Panotools::Script',
    'EXE_FILES'         => [ 'bin/cubic2erect', 'bin/erect2cubic',
        'bin/jpeg2qtvr', 'bin/erect2qtvr', 'bin/enblend-mask', 'bin/match-n-shift',
        'bin/process-masks', 'bin/erect2planet', 'bin/pto2tiff', 'bin/ptograph',
        'bin/tif2svg', 'bin/enblend-svg', 'bin/pto2fulla', 'bin/ptoinfo', 'bin/ptopath',
        'bin/qtvr2erect-gui', 'bin/tif2svg-gui', 'bin/ptoinfo-gui', 'bin/ptosort',
        'bin/process-masks-gui', 'bin/enblend-svg-gui', 'bin/erect2qtvr-gui',
        'bin/erect2mercator', 'bin/ptosplit', 'bin/ptomerge',
        'bin/transform-pano', 'bin/nona-mask', 'bin/qtvr2erect' ],
    'VERSION_FROM'      => 'lib/Panotools/Script.pm', # finds $VERSION
    'PREREQ_PM'         => {'bytes' => 0.0, 'File::Copy' => 1.0,
        'Getopt::Long' => 2.0, 'Pod::Usage' => 1.0, 'GraphViz' => 1.0,
        'Test::More' => 0.1, 'Math::Trig' => 0.1, 'File::Temp' => 0.1,
        'File::Spec' => 0.8, 'Image::Size' => 2.9, 'Storable' => 2.0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Panotools/Script.pm', # retrieve abstract from module
       AUTHOR     => 'Bruno Postle <bruno@postle.net>') : ()),
);

