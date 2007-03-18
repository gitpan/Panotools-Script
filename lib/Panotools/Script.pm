package Panotools::Script;

=head1 NAME

Panotools::Script - Panorama Tools scripting

=head1 SYNOPSIS

Read, manipulate and write Panorama Tools script files.

=head1 DESCRIPTION

Panorama Tools script files are used by several tools, including PTStitcher,
PTOptimizer, autooptimiser, nona and PTmender.

There are GUI tools to help create them: hugin, PTGui, PTAssembler,
autopano-sift and PTMac.

=cut

use strict;
use warnings;

use Panotools::Script::Line::Mode;
use Panotools::Script::Line::Panorama;
use Panotools::Script::Line::Image;
use Panotools::Script::Line::Output;
use Panotools::Script::Line::Control;
use Panotools::Script::Line::ControlMorph;
use Panotools::Script::Line::Variable;

use Panotools::Matrix qw(matrix2rollpitchyaw rollpitchyaw2matrix);
use Math::Trig;

use File::Temp qw/ tempfile /;
use File::Spec;

our $VERSION = 0.04;

our $CLEANUP = 1;
$CLEANUP = 0 if defined $ENV{DEBUG};

=head1 USAGE

  my $p = new Panotools::Script;

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {}, $class;
    $self->_defaults;
    return $self;
}

sub _defaults
{
    my $self = shift;
    $self->{mode} = new Panotools::Script::Line::Mode;
    $self->{panorama} = new Panotools::Script::Line::Panorama;
    $self->{variable} = new Panotools::Script::Line::Variable;
    $self->{image} = [];
    $self->{output} = [];
    $self->{control} = [];
    $self->{controlmorph} = [];
    $self->{stitcher} = 'PTmender';  # nona, PTmender, PTStitcher
    $self->{optimiser} = 'PTOptimizer'; # PTOptimizer, autooptimiser
    $self->{basedir} = File::Spec->rel2abs (File::Spec->curdir);
}

=pod

  $p->Read ('/path/to/script.txt');

=cut

sub Read
{
    my $self = shift;
    my $path = shift || return 0;
    open FILE, "<", $path or die "cannot read-open $path";
    my @raw = <FILE>;
    close FILE;

    my ($volume, $directories, $file) = File::Spec->splitpath ($path);
    $self->{basedir} = File::Spec->catpath ($volume, $directories, '');
    $self->{basedir} = File::Spec->rel2abs ($self->{basedir});

    for my $line (@raw)
    {
        $line =~ s/(\r|\n)//g;
        $self->{mode}->Parse ($line) if ($line =~ /^m /);
        $self->{panorama}->Parse ($line) if ($line =~ /^p /);
        $self->{variable}->Parse ($line) if ($line =~ /^v /);
        if ($line =~ /^i /)
        {
            my $image = new Panotools::Script::Line::Image;
            $image->Parse ($line);
            push @{$self->{image}}, $image;
        }
        if ($line =~ /^o /)
        {
            my $output = new Panotools::Script::Line::Output;
            $output->Parse ($line);
            push @{$self->{output}}, $output;
        }
        if ($line =~ /^c /)
        {
            my $control = new Panotools::Script::Line::Control;
            $control->Parse ($line);
            push @{$self->{control}}, $control;
        }
        if ($line =~ /^C /)
        {
            my $controlmorph = new Panotools::Script::Line::ControlMorph;
            $controlmorph->Parse ($line);
            push @{$self->{controlmorph}}, $controlmorph;
        }
    }
    $self->Output2Image;
    return 1;
}

=pod

  $p->Write ('/path/to/script.txt');

File paths in a Panorama Tools script file are generally relative to the
directory containing the script.  Modify this or otherwise prefix the filenames
by supplying an optional second argument:

  $p->Write ('/path/to/script.txt', '../path/to/prefix/tofiles');

=cut

sub Write
{
    my $self = shift;
    my $path = shift || return 0;
    my $vector = shift || '';
    open FILE, ">", $path or die "cannot write-open $path";
    print FILE "# Created by ". (ref $self) ." $VERSION\n\n";
    print FILE $self->{panorama}->Assemble;
    print FILE $self->{mode}->Assemble;
    print FILE "\n# Image lines\n";
    for my $image (@{$self->{image}})
    {
         print FILE $image->Assemble ($vector);
    }
    print FILE "\n# Variable lines\n";
    print FILE $self->{variable}->Assemble;
    print FILE "\n# Control point lines\n";
    for my $control (@{$self->{control}})
    {
         print FILE $control->Assemble;
    }
    for my $controlmorph (@{$self->{controlmorph}})
    {
         print FILE $controlmorph->Assemble;
    }
    print FILE "\n*\n";
    print FILE "\n# Output image lines\n";
    for my $output (@{$self->{output}})
    {
         print FILE $output->Assemble ($vector);
    }
    close FILE;
}

=pod

Optimise image parameters in a project:

  $p->Optimise;

=cut

sub Optimise
{
    my $self = shift;
    my ($fh, $tempfile) = tempfile (SUFFIX => '.txt', UNLINK => $CLEANUP);
    $self->Write ($tempfile);
    `$self->{optimiser} $tempfile`;
    return 0 unless ($? == 0);
    my $try = new Panotools::Script;
    $try->Read ($tempfile) || return 0;
    $self->{output} = $try->{output};
    $self->Output2Image;
    return 1;
}

=pod

Rotate transform all the images in a project, angles in degrees:

  $p->Transform ($roll, $pitch, $yaw);

=cut

sub Transform
{
    my $self = shift;
    my ($roll, $pitch, $yaw) = @_;
    my @transform_rpy = map (deg2rad ($_), ($roll, $pitch, $yaw));
    my $transform_matrix = rollpitchyaw2matrix (@transform_rpy);
    for my $image (@{$self->{image}})
    {
        my @rpy = map (deg2rad ($_), ($image->{r}, $image->{p}, $image->{y}));
        my $matrix = rollpitchyaw2matrix (@rpy);
        my $result = $transform_matrix->multiply ($matrix);
        my ($r, $p, $y) = map (rad2deg ($_), matrix2rollpitchyaw ($result));
        $image->{r} = $r;
        $image->{p} = $p;
        $image->{y} = $y;
    }
    $self->Image2Output;
}

=pod

'o' output lines are generated by PTOptimizer and contain stitching parameters
for each input image.
'i' image lines provide parameters for optimisation as well as stitching.

Update the 'image' lines based on 'output' lines and vice-versa like so:

  $p->Output2Image;
  $p->Image2Output;

=cut

sub Output2Image
{
    my $self = shift;
    for my $index (0 .. (@{$self->{output}} - 1))
    {
        for my $entry (keys %{$self->{output}->[$index]})
        {
            $self->{image}->[$index] = new Panotools::Script::Line::Image unless (defined $self->{image}->[$index]);
            $self->{image}->[$index]->{$entry} = $self->{output}->[$index]->{$entry}
                unless (defined $self->{image}->[$index]->{$entry} and $self->{image}->[$index]->{$entry} =~ /=/);
        }
    }
}

sub Image2Output
{
    my $self = shift;
    for my $index (0 .. (@{$self->{image}} - 1))
    {
        for my $entry (keys %{$self->{image}->[$index]})
        {
            $self->{output}->[$index] = new Panotools::Script::Line::Output unless (defined $self->{output}->[$index]);
            unless ($self->{image}->[$index]->{$entry} =~ /=/)
            {
                $self->{output}->[$index]->{$entry} = $self->{image}->[$index]->{$entry};
            }
            else
            {
                my $base = $self->{image}->[$index]->{$entry};
                $base =~ s/=//;
                $self->{output}->[$index]->{$entry} = $self->{image}->[$base]->{$entry};
            }
        }
    }
}

=pod

Stitch a project:

  $p->Stitch ('/path/to/output.jpg');

=cut

sub Stitch
{
    my $self = shift;
    my $outfile = shift;
    my ($fh, $tempfile) = tempfile (SUFFIX => '.txt', UNLINK => $CLEANUP);
    $self->Image2Output;
    my $vector = File::Spec->abs2rel ($self->{basedir}, File::Spec->tmpdir);
    $self->Write ($tempfile, $vector);
    my $cwd = File::Spec->curdir;
    chdir (File::Spec->tmpdir);
    `$self->{stitcher} $tempfile -o $outfile`;
    chdir ($cwd);
    return 0 unless ($? == 0);
    return 1;
}

1;

