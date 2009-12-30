package Panotools::Photos;

=head1 NAME

Panotools::Photos - Photo sets

=head1 SYNOPSIS

Query sets of photos

=head1 DESCRIPTION

A collection of photos has possibilities, it could be one or more panoramas or a
bracketed set.  This module provides some methods for describing groups of
photos based on available metadata

=cut

use strict;
use warnings;

use File::Spec;
use Image::ExifTool;

=head1 USAGE

Create a new object like so:

  my $photos = new Panotools::Photos;

Alternatively supply some filenames:

  my $photos = new Panotools::Photos ('DSC_0001.JPG', 'DSC_0002.JPG');

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless [], $class;
    $self->Paths (@_);
    return $self;
}

=pod

Add to or get the list of image filenames:

  $photos->Paths ('DSC_0003.JPG', 'DSC_0004.JPG');
  my @paths = $photos->Paths;

=cut

sub Paths
{
    my $self = shift;
    for my $path (@_)
    {
        push @{$self}, {path => $path, exif => Image::ExifTool::ImageInfo ($path)};
    }
    return map ($_->{path}, @{$self});
}

=pod

Construct a stub filename from the names of the first and last images in the
list.

  my $stub = $photos->Stub;

e.g. DSC_0001.JPG DSC_0002.JPG DSC_0003.JPG -> DSC_0001-DSC_0003

=cut

sub Stub
{
    my $self = shift;
    my $path_a = $self->[0]->{path};
    my $path_b = $self->[-1]->{path};
    # strip any suffixes
    $path_a =~ s/\.[[:alnum:]]+$//;
    $path_b =~ s/\.[[:alnum:]]+$//;
    # strip all but filename
    $path_b =~ s/.*[\/\\]//;
    return $path_a .'-'. $path_b;
}

=pod

Query to discover if this is a likely bracketed set.  i.e. is the total number
of photos divisible by the number of different exposures:

  &do_stuff if ($photos->Bracketed);

=cut

sub Bracketed
{   
    my $self = shift;
    # bracketed photos are not shot on 'Auto Exposure'
    for my $index (0 .. scalar @{$self} -1)
    {
        next unless defined $self->[$index]->{exif}->{ExposureMode};
        return 0 if $self->[$index]->{exif}->{ExposureMode} eq 'Auto';
    }
    my $brackets = scalar (@{$self->Speeds});
    # require equal numbers of each exposure level
    return 0 if (scalar (@{$self}) % $brackets);
    # require more than one exposure level
    return 0 if ($brackets < 2);
    # require bracketing order repeats: 1/50 1/100 1/200 1/50 1/100 1/200 etc...
    for my $index ($brackets .. scalar @{$self} -1)
    {
        return 0 unless $self->[$index]->{exif}->{ExposureTime} eq $self->[$index - $brackets]->{exif}->{ExposureTime};
    }

    return 1;
}

=pod

Query to discover if this is a layered set, i.e. there is a large exposure
difference in the set, but it isn't bracketed.

  &do_stuff if ($photos->Layered);

By default the threshold is 4, e.g. exposures varying between 2 and 1/2
seconds indicate layers.  Vary this threshold like so:

  &do_stuff if ($photos->Layered (2));

=cut

sub Layered
{
    my $self = shift;
    my $factor = shift || 4;
    return 0 if $self->Bracketed;
    my $longest = $self->Speeds->[0];
    my $shortest = $self->Speeds->[-1];
    if ($longest =~ /^1\/([0-9]+)$/) {$longest = 1 / $1};
    if ($shortest =~ /^1\/([0-9]+)$/) {$shortest = 1 / $1};
    return 0 unless $longest or $shortest;
    return 0 if $longest / $shortest < $factor;
    return 1;
}

=pod

Get a list of exposure times sorted with longest exposure first

  @speeds = @{$photos->Speeds};

=cut

sub Speeds
{
    my $self = shift;
    my $speeds = {};
    for my $image (@{$self})
    {
        my $et = $image->{exif}->{ExposureTime} || $image->{exif}->{ShutterSpeed} || 0;
        $speeds->{$et} = 'TRUE';
    }
    return [sort {_longer ($b, $a)} keys (%{$speeds})];
}

sub _longer
{
    my ($a, $b) = @_;
    if ($a =~ /^1\/([0-9]+)$/) {$a = 1 / $1};
    if ($b =~ /^1\/([0-9]+)$/) {$b = 1 / $1};
    return 0 if ($b > $a);
    return 1;
}

=pod

Given a set of photos, split it into a one or more sets by looking at the
variation of time interval between shots.  e.g. typically the interval between
shots in a panorama varies by less than 15 seconds.  A variation greater than
that indicates the start of the next panorama:

  my @sets = $photos->SplitInterval (15);

Sets with an average interval greater than 4x this variation are not considered
panoramas at all and discarded.

=cut

sub SplitInterval
{
    my $self = shift;
    my $d_inc = shift || 15;
    my $max_inc = $d_inc * 4;
    my @groups;
    
    my $group_tmp = new Panotools::Photos;
    my $previous_time;
    my $previous_inc = 0;
    for my $image (@{$self})
    {
        my $datetime = $image->{exif}->{'DateTimeOriginal'} || $image->{exif}->{'FileModifyDate'};
        my $time_unix = Image::ExifTool::GetUnixTime ($datetime);
        $previous_time = $time_unix unless (defined $previous_time);
        my $inc = $time_unix - $previous_time;
    
        if (($inc - $previous_inc) > $d_inc)
        {
            push @groups, $group_tmp if ($group_tmp->AverageInterval < $max_inc);
            $group_tmp = new Panotools::Photos;
        }
        push @{$group_tmp}, $image;
    
        $previous_time = $time_unix;
        $previous_inc = $inc;
    }
    push @groups, $group_tmp if ($group_tmp->AverageInterval < $max_inc);
    return @groups;
}

=pod

Get the average time between shots:

  $average = $photos->AverageInterval;

=cut

sub AverageInterval
{
    my $self = shift;
    return 0 unless (scalar @{$self} > 1);

    my $start = $self->[0]->{exif}->{'DateTimeOriginal'} || $self->[0]->{exif}->{'FileModifyDate'};
    my $end = $self->[-1]->{exif}->{'DateTimeOriginal'} || $self->[-1]->{exif}->{'FileModifyDate'};

    my $totaltime = Image::ExifTool::GetUnixTime ($end) - Image::ExifTool::GetUnixTime ($start);
    return $totaltime / (scalar @{$self} -1);
}

=pod

Get the Angle of View in degrees of the first photo:

  $photos->FOV;

..or any other photo (-1 is last):

  $photos->FOV (123);

Returns undef if the FOV can't be calculated.

=cut

sub FOV
{
    my $self = shift;
    my $index = 0;
    $index = shift if @_;
    my $fov = $self->[$index]->{exif}->{'FOV'};
    $fov =~ s/[^0-9.]*$// if defined $fov;
    return $fov;
}

sub Rotation
{
    my $self = shift;
    my $index = shift || 0;
    my $rotation = $self->[$index]->{exif}->{'Rotation'} || undef;
    return 0 unless $rotation;
    return 0 if $rotation =~ /Mirror/; 
    return 0 if ($self->[$index]->{exif}->{'ImageWidth'}
                     < $self->[$index]->{exif}->{'ImageHeight'});
    return 90 if $rotation =~ /Rotate 90 CW/;
    return 180 if $rotation =~ /Rotate 180/;
    return -90 if $rotation =~ /Rotate 270 CW/;
    return 0;

#    1 => 'Horizontal (normal)',
#    3 => 'Rotate 180',
#    6 => 'Rotate 90 CW',
#    8 => 'Rotate 270 CW',

#    2 => 'Mirror horizontal',
#    4 => 'Mirror vertical',
#    5 => 'Mirror horizontal and rotate 270 CW',
#    7 => 'Mirror horizontal and rotate 90 CW',

}

=pod

Get an EV value for a photo, this will be guessed from partial EXIF data:

  $photos->Eev ($index);

=cut

sub Eev
{
    my $self = shift;
    my $index = shift || 0;
    my $exif = $self->[$index]->{exif};
    my $aperture = $exif->{Aperture} || 1.0;
    my $et = $exif->{ExposureTime} || $exif->{ShutterSpeed} || 1.0;
    if ($et =~ /^1\/([0-9]+)$/) {$et = 1 / $1};
    my $iso = $exif->{ISO} || 100;
    # (A light value of 0 is defined as f/1.0 at 1 second with ISO 100)
    return sprintf ('%.3f', (2*log ($aperture) - log($et) - log($iso/100)) / log(2));
}

1;
