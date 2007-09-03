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

use File::Temp qw/ tempdir /;
use File::Spec;

use Storable qw/ dclone /;

our $VERSION = 0.09;

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
    $self->{stitcher} = $ENV{STITCHER} || 'nona';  # nona, PTmender, PTStitcher, Tmender
    $self->{optimiser} = $ENV{OPTIMISER} || 'autooptimiser'; # PToptimizer PTOptimizer, autooptimiser
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
        $self->Mode->Parse ($line) if ($line =~ /^m /);
        $self->Panorama->Parse ($line) if ($line =~ /^p /);
        $self->Variable->Parse ($line) if ($line =~ /^v /);
        if ($line =~ /^i /)
        {
            my $image = new Panotools::Script::Line::Image;
            $image->Parse ($line);
            push @{$self->Image}, $image;
        }
        if ($line =~ /^o /)
        {
            my $output = new Panotools::Script::Line::Output;
            $output->Parse ($line);
            push @{$self->Output}, $output;
        }
        if ($line =~ /^c /)
        {
            my $control = new Panotools::Script::Line::Control;
            $control->Parse ($line);
            push @{$self->Control}, $control;
        }
        if ($line =~ /^C /)
        {
            my $controlmorph = new Panotools::Script::Line::ControlMorph;
            $controlmorph->Parse ($line);
            push @{$self->ControlMorph}, $controlmorph;
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
    print FILE $self->Panorama->Assemble;
    print FILE $self->Mode->Assemble;
    print FILE "\n# Image lines\n";
    for my $image (@{$self->Image})
    {
         print FILE $image->Assemble ($vector);
    }
    print FILE "\n# Variable lines\n";
    print FILE $self->Variable->Assemble;
    print FILE "\n# Control point lines\n";
    for my $control (@{$self->Control})
    {
         print FILE $control->Assemble;
    }
    for my $controlmorph (@{$self->ControlMorph})
    {
         print FILE $controlmorph->Assemble;
    }
    print FILE "\n*\n";
    print FILE "\n# Output image lines\n";
    for my $output (@{$self->Output})
    {
         print FILE $output->Assemble ($vector);
    }
    close FILE;
}

=pod

Clone a script object

 $clone = $p->Clone;

=cut

sub Clone
{
    my $self = shift;
    dclone ($self);
}

=pod

Preview a project (requires ImageMagick)

 $p->Preview;

=cut

sub Preview
{
    my $self = shift;
    my $tempdir = tempdir (CLEANUP => $CLEANUP);
    my $tempfile = File::Spec->catfile ($tempdir, 'preview.jpg');
    my $aspect = $self->Panorama->{w} / $self->Panorama->{h};
    my $clone = $self->Clone;
    my $height = sqrt (40000 / $aspect);
    my $width = $aspect * $height;
    $clone->Panorama->Set (w => int ($width), h => int ($height), n => '"JPEG"');
    $clone->Stitch ($tempfile);
    system ('display', '-sample', '200%', $tempfile);
}

=pod

Access various sections of the scriptfile:

 $p->Mode;          # a L<Panotools::Script::Line::Mode> object
 $p->Panorama;      # a L<Panotools::Script::Line::Panorama> object
 $p->Variable;      # a L<Panotools::Script::Line::Variable> object

=cut

sub Mode
{
    my $self = shift;
    $self->{mode};
}

sub Panorama
{
    my $self = shift;
    $self->{panorama};
}

sub Variable
{
    my $self = shift;
    $self->{variable};
}

=pod

 $p->Image;         # an array of L<Panotools::Script::Line::Image> objects
 $p->Output;        # an array of L<Panotools::Script::Line::Output> objects
 $p->Control;       # an array of L<Panotools::Script::Line::Control> objects
 $p->ControlMorph;  # an array of L<Panotools::Script::Line::ControlMorph> objects

=cut

sub Image
{
    my $self = shift;
    $self->{image};
}

sub Output
{
    my $self = shift;
    $self->{output};
}

sub Control
{
    my $self = shift;
    $self->{control};
}

sub ControlMorph
{
    my $self = shift;
    $self->{controlmorph};
}

=pod

Optimise image parameters in a project:

  $p->Optimise;

=cut

sub Optimise
{
    my $self = shift;
    $self->Image2Output;
    my $tempdir = tempdir (CLEANUP => $CLEANUP);
    my $tempfile = File::Spec->catfile ($tempdir, 'optimise.txt');
    my $outfile = File::Spec->catfile ($tempdir, 'outfile.txt');
    my $clone = $self->Clone;
    for my $image (@{$clone->Image})
    {
        $image->_sanitise_ptoptimizer;
    }
    $clone->Write ($tempfile);
    my $try = new Panotools::Script;
    if ($self->{optimiser} =~ /autooptimiser/)
    {
        system ($self->{optimiser}, '-p', '-o', $outfile, $tempfile);
        return 0 unless ($? == 0);
        $try->Read ($outfile) || return 0;
        $try->Image2Output;
    }
    else
    {
        system ($self->{optimiser}, $tempfile);
        return 0 unless ($? == 0);
        $try->Read ($tempfile) || return 0;
    }
    for my $index (0 .. scalar (@{$try->Output}) - 1)
    {
        for my $key (keys %{$try->Output->[$index]})
        {
            my $value = $try->Output->[$index]->{$key};
            $self->Output->[$index]->Set ($key => $value);
        }
    }
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
    for my $image (@{$self->Image})
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
    for my $index (0 .. (@{$self->Output} - 1))
    {
        for my $entry (keys %{$self->Output->[$index]})
        {
            $self->Image->[$index] = new Panotools::Script::Line::Image unless (defined $self->Image->[$index]);
            $self->Image->[$index]->{$entry} = $self->Output->[$index]->{$entry}
                unless (defined $self->Image->[$index]->{$entry} and $self->Image->[$index]->{$entry} =~ /=/);
        }
    }
}

sub Image2Output
{
    my $self = shift;
    for my $index (0 .. (@{$self->Image} - 1))
    {
        for my $entry (keys %{$self->Image->[$index]})
        {
            $self->Output->[$index] = new Panotools::Script::Line::Output unless (defined $self->Output->[$index]);
            unless ($self->Image->[$index]->{$entry} =~ /=/)
            {
                $self->Output->[$index]->{$entry} = $self->Image->[$index]->{$entry};
            }
            else
            {
                my $base = $self->Image->[$index]->{$entry};
                $base =~ s/=//;
                $self->Output->[$index]->{$entry} = $self->Image->[$base]->{$entry};
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
    my @options = @_;
    my $tempdir = tempdir (CLEANUP => $CLEANUP);
    my $tempfile = File::Spec->catfile ($tempdir, 'stitch.txt');
    $self->Image2Output;
    my $vector = File::Spec->abs2rel ($self->{basedir}, $tempdir);
    $self->Write ($tempfile, $vector);
    my $cwd = File::Spec->curdir;
    chdir ($tempdir);
    system ($self->{stitcher}, @options, '-o', $outfile, $tempfile);
    chdir ($cwd);
    return 0 unless ($? == 0);
    return 1;
}

1;

