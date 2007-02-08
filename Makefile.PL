use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Panotools::Script',
    'EXE_FILES'         => [ 'bin/cubic2erect', 'bin/erect2cubic', 'bin/jpeg2qtvr', 'bin/enblend-mask', 'bin/process-masks', 'bin/erect2planet', 'bin/pto2tiff', 'bin/transform-pano' ],
    'VERSION_FROM'      => 'lib/Panotools/Script.pm', # finds $VERSION
    'PREREQ_PM'         => {'Math::Matrix' => 0.4, 'Image::Magick' => 5.0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Panotools/Script.pm', # retrieve abstract from module
       AUTHOR     => 'Bruno Postle <bruno@postle.net>') : ()),
);

