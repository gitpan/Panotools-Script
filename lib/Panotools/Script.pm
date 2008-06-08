package Panotools::Script;

=head1 NAME

Panotools::Script - Panorama Tools scripting

=head1 SYNOPSIS

Read, write and manipulate hugin script files.

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
use Panotools::Script::Line::Option;
use Panotools::Script::Line::Image;
use Panotools::Script::Line::ImageMetadata;
use Panotools::Script::Line::Output;
use Panotools::Script::Line::Control;
use Panotools::Script::Line::ControlMorph;
use Panotools::Script::Line::Variable;

use File::Temp qw/ tempdir /;
use File::Spec;

use Storable qw/ dclone /;

our $VERSION = 0.14;

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
    $self->{option} = new Panotools::Script::Line::Option;
    $self->{variable} = new Panotools::Script::Line::Variable;
    $self->{image} = [];
    $self->{imagemetadata} = [];
    $self->{output} = [];
    $self->{control} = [];
    $self->{controlmorph} = [];
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

    for my $line (@raw)
    {
        $line =~ s/(\r|\n)//g;
        $self->Mode->Parse ($line) if ($line =~ /^m /);
        $self->Panorama->Parse ($line) if ($line =~ /^p /);
        $self->Option->Parse ($line) if ($line =~ /^#hugin_/);
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
        if ($line =~ /^#-hugin /)
        {
            # per-image metadata
            my $imagemeta = new Panotools::Script::Line::ImageMetadata;
            $imagemeta->Parse ($line);
            push @{$self->ImageMetadata}, $imagemeta;
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
    for my $index (0 .. (scalar (@{$self->Image}) - 1))
    {
        print FILE $self->ImageMetadata->[$index]->Assemble if defined ($self->ImageMetadata->[$index]);
        print FILE $self->Image->[$index]->Assemble if defined ($self->Image->[$index]);
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
    print FILE "\n# option lines\n";
    print FILE $self->Option->Assemble;
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

sub Option
{
    my $self = shift;
    $self->{option};
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

sub ImageMetadata
{
    my $self = shift;
    $self->{imagemetadata};
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

Rotate transform all the images in a project, angles in degrees:

  $p->Transform ($roll, $pitch, $yaw);

=cut

sub Transform
{
    my $self = shift;
    my ($roll, $pitch, $yaw) = @_;
    for my $image (@{$self->Image})
    {
        $image->Transform ($roll, $pitch, $yaw);
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

=head1 COPYRIGHT

Copyright (c) 2001 Bruno Postle <bruno@postle.net>. All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public
License along with this software; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut

1;

