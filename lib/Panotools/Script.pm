package Panotools::Script;

=head1 NAME

Panotools::Script - Panorama Tools scripting

=head1 SYNOPSIS

Read, write and manipulate hugin script files.

=head1 DESCRIPTION

Library and utilities for manipulating project files created by the hugin photo
stitching software.

This file format is shared with various other tools, in particular this module
is also capable of working with Panorama Tools script files.

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

our $VERSION = '0.23';

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
    $self->_defaults;
    my $path = shift || return 0;
    if ($path eq '-')
    {
        open FILE, '<-';
    }
    else
    {
        open FILE, "<", $path or die "cannot read-open $path";
    }
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
    $self->Image2Output if scalar @{$self->Output};
    my $path = shift || return 0;
    my $vector = shift || '';
    if ($path eq '-')
    {
        open FILE, '>-';
    }
    else
    {
        open FILE, ">", $path or die "cannot write-open $path";
    }
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
    $self->{control} = shift if scalar @_;
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

=pod

Remove duplicate control points from the project, returns a list of deleted
points:

  my $deleted = $p->Duplicates;

=cut

sub Duplicates
{
    my $self = shift;
    my $packed_seen = {};
    my $points_uniq = [];
    my $points_deleted = [];
    for my $point (@{$self->Control})
    {
        my $packed = $point->Packed;
        if (defined $packed_seen->{$packed})
        {   
            push @{$points_deleted}, $point;
        }
        else
        {   
            push @{$points_uniq}, $point;
        }
        $packed_seen->{$packed} = 'TRUE';
    }

    $self->Control ($points_uniq);
    return $points_deleted;
}

=pod

Remove all points with an error distance greater than a threshold measured in
pixels, returns a list of deleted points:

  my $pruned = $p->Prune (12.345);

=cut

sub Prune
{
    my $self = shift;
    my $threshold = shift;
    return [] unless $threshold > 0;
    my $points_new = [];
    my $points_pruned = [];

    for my $point (@{$self->Control})
    {
        if ($point->{t} > 0 or $point->Distance ($self) < $threshold)
        {
            push @{$points_new}, $point;
        }
        else
        {
            push @{$points_pruned}, $point;
        }
    }

    $self->{control} = $points_new;
    return $points_pruned;
}

=pod

Extract a new object consisting of just the requested images, related
control points and optimisation settings:

  my $subset = $p->Subset (1, 2, 34, 56);

Images can be requested in any order, but they will be returned in the same
order as the 'parent' project.

=cut

sub Subset
{
    my $self = shift;
    my @selection = sort {$a <=> $b} @_;

    my $mapping;
    for my $index (0 .. scalar @selection -1)
    {
        return 0 unless $selection[$index] =~ /^[0-9]+$/;
        return 0 if $selection[$index] >= scalar @{$self->{image}};
        $mapping->{$selection[$index]} = $index;
    }
    return 0 unless scalar keys %{$mapping} == scalar @selection;

    my $pto_out = $self->Clone;

    # only use selected images
    $pto_out->{image} = [];
    $pto_out->{imagemetadata} = [];
    $pto_out->{variable} = new Panotools::Script::Line::Variable;

    for my $index (0 .. scalar @{$self->{image}} -1)
    {
        next unless defined $mapping->{$index};

        # copy metadata for selected image
        $pto_out->{imagemetadata}->[$mapping->{$index}]
            = $self->{imagemetadata}->[$index]->Clone;

        # copy selected image but resolve '=0' style references
        my $image = $self->{image}->[$index]->Clone;
        for my $key (keys %{$image})
        {
            # resolve references as anchor image may be gone
            if ($image->{$key} =~ /^=([0-9]+)$/)
            {
                $image->{$key} = $self->{image}->[$1]->{$key};
            }
            # rereference to image 0 if possible
            if (scalar @{$pto_out->{image}} > 0
                  and $image->{$key} eq $pto_out->{image}->[0]->{$key}
                  and $key =~ /^([abcdev]|R[abcde]|V[abcdxy])$/)
            {
                $image->{$key} = '=0';
            }
        }
        $pto_out->{image}->[$mapping->{$index}] = $image;

        # copy only optimisation parameters for selected image
        $pto_out->{variable}->{$mapping->{$index}}
            = {%{$self->{variable}->{$index}}}
            if defined $self->{variable}->{$index};
    }

    # copy only control points related to selected images
    $pto_out->{control} = [];
    for my $control (@{$self->{control}})
    {
        next unless defined $mapping->{$control->{n}};
        next unless defined $mapping->{$control->{N}};
        my $clone = $control->Clone;
        $clone->{n} = $mapping->{$control->{n}};
        $clone->{N} = $mapping->{$control->{N}};
        push @{$pto_out->{control}}, $clone;
    }

    return $pto_out;
}

=pod

Merge a project with another:

  $p->Merge ($newstuff);

This adds extra images from $newstuff, skipping duplicates.  All control points
except exact duplicates are imported regardless.

=cut

sub Merge
{
    my $self = shift;
    my $b = shift || return 0;

    # create lookup table relating filenames to index in final project
    my $mapping = {};

    for my $index (0 .. scalar @{$self->Image} -1)
    {
        $mapping->{$self->Image->[$index]->{n}} = $index;
    }

    my $index = scalar keys %{$mapping};
    for my $image (@{$b->Image})
    {
        unless (defined $mapping->{$image->{n}})
        {
            $mapping->{$image->{n}} = $index;
            $index++;
        }
    }

    # insert metadata, image and variable info if a new filename
    for my $index (0 .. scalar @{$b->Image} -1)
    {
        my $filename = $b->Image->[$index]->{n};
        next if defined $self->Image->[$mapping->{$filename}];

        $self->ImageMetadata->[$mapping->{$filename}] = $b->ImageMetadata->[$index]->Clone
            if defined $b->ImageMetadata->[$index];

        my $image = $b->Image->[$index]->Clone;
        for my $key (keys %{$image})
        {
            # update references
            if ($image->{$key} =~ /^=([0-9]+)$/)
            {
                my $index_new = $mapping->{$b->Image->[$1]->{n}};
                $image->{$key} = "=$index_new";
            }
        }
        $self->Image->[$mapping->{$filename}] = $image;

        my $variable = $b->Variable->Clone;
        $self->Variable->{$mapping->{$filename}} = $variable->{$index};
    }

    # append control points
    for my $control (@{$b->Control})
    {
        my $clone = $control->Clone;
        $clone->{n} = $mapping->{$b->Image->[$clone->{n}]->{n}};
        $clone->{N} = $mapping->{$b->Image->[$clone->{N}]->{n}};
        push @{$self->Control}, $clone;
    }

    $self->Duplicates;

    return 1;
}

=pod

Get a summary of control point error distances in pixel units scaled to the
output panorama:

  my ($total, $min, $max, $average, $sigma) = $p->Stats;

=cut

sub Stats
{
    my $self = shift;

    # get a list of all the distances
    my @distances;
    for my $point (@{$self->Control})
    {
        next unless $point->{t} == 0;
        push @distances, $point->Distance ($self);
    }

    my $total = scalar (@distances);

    return (0,0,0,0,0) unless $total;

    # calculate maximum and average distance
    my $max = undef;
    my $min = undef;
    my $sum = 0;
    for my $distance (@distances)
    {
        $min = $distance unless defined $min;
        $min = $distance if ($min > $distance);
        $max = $distance unless defined $max;
        $max = $distance if ($max < $distance);
        $sum += $distance;
    }
    my $average = $sum / $total;

    # calculate variation and standard deviation (sigma)
    $sum = 0;
    for my $distance (@distances)
    {
        my $variation = $distance - $average;
        $sum += $variation * $variation;
    }
    my $variance = $sum / $total;
    my $sigma = sqrt ($variance);

    return ($total, $min, $max, $average, $sigma);
}

=pod

Centre input images into the final panorama:

   $p->Centre ('y');
   $p->Centre ('p');
   $p->Centre ('r');

=cut

sub Centre
{
    my $self = shift;
    my $param = shift;

    for my $image (@{$self->Image})
    {
        my $sigma_old = $self->Sigma ($param);
        $image->{$param} += 360;
        next if $self->Sigma ($param) < $sigma_old;
        $image->{$param} -= 720;
        next if $self->Sigma ($param) < $sigma_old;
        $image->{$param} += 360;
    }

    my $average_r = $self->_average ('r');
    my $average_p = $self->_average ('p');
    my $average_y = $self->_average ('y');

    if ($param eq 'r')
    {
        $self->Transform (0, 0, 0 - $average_y);
          $self->Transform (0, 0 - $average_p, 0);
            $self->Transform (0 - $average_r, 0, 0);
          $self->Transform (0, $average_p, 0);
        $self->Transform (0, 0, $average_y);
    }
    if ($param eq 'p')
    {
        $self->Transform (0, 0, 0 - $average_y);
          $self->Transform (0, 0 - $average_p, 0);
        $self->Transform (0, 0, $average_y);
    }
    if ($param eq 'y')
    {
        $self->Transform (0, 0, 0 - $average_y);
    }
}

sub _average
{
    my $self = shift;
    my $param = shift;
    my $sum = 0;
    for my $image (@{$self->Image})
    {
        $sum += $image->{$param}
    }
    return $sum / scalar @{$self->Image};
}

sub Sigma
{
    my $self = shift;
    my $param = shift;
    my $sum = 0;
    my $average = $self->_average ($param);
    for my $image (@{$self->Image})
    {
        my $variation = $image->{$param} - $average;
        $sum += $variation * $variation;
    }
    my $variance = $sum / scalar @{$self->Image};
    return sqrt ($variance);
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

