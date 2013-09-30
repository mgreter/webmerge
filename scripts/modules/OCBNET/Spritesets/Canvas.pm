###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# this is the main canvas or root block to be drawn
# it contains four stacked frames on each side, four
# more edge areas, four corner areas and one in the
# center where the sprites are packed into minimal space
####################################################################################################
package OCBNET::Spritesets::Canvas;
####################################################################################################

use strict;
use warnings;

####################################################################################################

use OCBNET::Spritesets::Canvas::Layout;
use OCBNET::Spritesets::Canvas::Optimize;
use OCBNET::Spritesets::Canvas::Repeater;
use OCBNET::Spritesets::Canvas::Distribute;

####################################################################################################

use base 'OCBNET::Spritesets::Container';

####################################################################################################

# all areas where we can
# have a child container
my @areas =
(
	'corner-lt',
	'stack-t',
	'edge-t',
	'corner-rt',
	'stack-l',
	'middle',
	'stack-r',
	'edge-l',
	'edge-r',
	'corner-lb',
	'stack-b',
	'edge-b',
	'corner-rb'
);

####################################################################################################

# create a new object
# ******************************************************************************
sub new
{

	# get package name, parent and options
	my ($pckg, $parent, $options) = @_;

	# get object by calling super class
	my $self = $pckg->SUPER::new($parent);

	# this is the base container which will be rendered and
	# saved to a file, so we always have 0/0 as coordinates
	$self->left = 0; $self->top = 0;

	# initialize the width and the height
	$self->width = 0; $self->height = 0;

	# array with all sprites
	$self->{'sprites'} = [];

	# debug mode variable
	$self->{'debug'} = $options->{'debug'};

	# assign or init the options hash
	$self->{'options'} = $options || {};

	# create and initialize the fitter area (if used or not)
	$self->{'middle'} = new OCBNET::Spritesets::Fit($self);

	# create and initialize the sub areas (if used or not)
	$self->{'edge-t'} = new OCBNET::Spritesets::Edge($self, 0, 0);
	$self->{'edge-r'} = new OCBNET::Spritesets::Edge($self, 1, 1);
	$self->{'edge-b'} = new OCBNET::Spritesets::Edge($self, 0, 1);
	$self->{'edge-l'} = new OCBNET::Spritesets::Edge($self, 1, 0);

	# create and initialize the sub areas (if used or not)
	$self->{'stack-t'} = new OCBNET::Spritesets::Stack($self, 0, 0);
	$self->{'stack-r'} = new OCBNET::Spritesets::Stack($self, 1, 1);
	$self->{'stack-b'} = new OCBNET::Spritesets::Stack($self, 0, 1);
	$self->{'stack-l'} = new OCBNET::Spritesets::Stack($self, 1, 0);

	# create and initialize the sub areas (if used or not)
	$self->{'corner-lt'} = new OCBNET::Spritesets::Corner($self, 0, 0);
	$self->{'corner-rt'} = new OCBNET::Spritesets::Corner($self, 1, 0);
	$self->{'corner-lb'} = new OCBNET::Spritesets::Corner($self, 0, 1);
	$self->{'corner-rb'} = new OCBNET::Spritesets::Corner($self, 1, 1);

	# register the name of each area (debug only)
	$self->{$_}->{'name'} = $_ foreach @areas;

	# if in debug mode we assign background colors
	# this way you can see what got distributed where
	if ($self->{'debug'})
	{
		$self->{'middle'}->{'bg'} = 'xc:rgba(0, 255, 0, 0.25)';
		$self->{'edge-t'}->{'bg'} = 'xc:rgba(150, 30, 0, 0.25)';
		$self->{'edge-r'}->{'bg'} = 'xc:rgba(150, 80, 0, 0.25)';
		$self->{'edge-b'}->{'bg'} = 'xc:rgba(150, 130, 0, 0.25)';
		$self->{'edge-l'}->{'bg'} = 'xc:rgba(150, 180, 0, 0.25)';
		$self->{'stack-t'}->{'bg'} = 'xc:rgba(30, 0, 150, 0.25)';
		$self->{'stack-r'}->{'bg'} = 'xc:rgba(80, 0, 150, 0.25)';
		$self->{'stack-b'}->{'bg'} = 'xc:rgba(130, 0, 150, 0.25)';
		$self->{'stack-l'}->{'bg'} = 'xc:rgba(180, 0, 150, 0.25)';
		$self->{'corner-lt'}->{'bg'} = 'xc:rgba(0, 150, 30, 0.25)';
		$self->{'corner-rt'}->{'bg'} = 'xc:rgba(0, 150, 80, 0.25)';
		$self->{'corner-lb'}->{'bg'} = 'xc:rgba(0, 150, 130, 0.25)';
		$self->{'corner-rb'}->{'bg'} = 'xc:rgba(0, 150, 180, 0.25)';
	}

	# add the widgets to parent
	foreach my $area ($self->areas)
	{ $self->SUPER::add($area); }

	# reset the children array
	$self->{'children'} = [];

	# return object
	return $self;

}
# EO new

####################################################################################################

sub areas { return map { $_[0]->{$_} } @areas; }

####################################################################################################
# add a sprite to the canvas - put it into the
# correct area according to its configuration
####################################################################################################

# ******************************************************************************
sub add
{

	# get method arguments
	my ($self, $sprite) = @_;

	# push the sprite on to the array
	push (@{$self->{'sprites'}}, $sprite);

	# success
	return 1;

}
# EO add

####################################################################################################


####################################################################################################

sub draw
{

	# get our object
	my ($self) = @_;

	# initialize empty image
	$self->{'image'}->Set(matte => 'True');
	$self->{'image'}->Set(magick => 'png');
	$self->{'image'}->Set(size => $self->size);
	$self->{'image'}->ReadImage($self->{'bg'});
	$self->{'image'}->Quantize(colorspace=>'RGB');

	# process all possible areas
	foreach my $area ($self->areas)
	{

		# ignore area if it's empty
		next if $area->empty;

		# get our own dimensions
		my $width = $self->width;
		my $height = $self->height;

		##########################################################
		# draw main areas on the canvas
		##########################################################

		# draw background on canvas
		if ($area->{'img-bg'})
		{
			$self->{'image'}->Composite(
				compose => 'Over',
				x => $area->left,
				y => $area->top,
				image => $area->{'img-bg'}
			);
		}

		# draw foreground on canvas
		$self->{'image'}->Composite(
			compose => 'Over',
			x => $area->left,
			y => $area->top,
			image => $area->draw
		);

	}
	# EO each area

	# call repeater
	$self->repeater;

	# return the image instance
	return $self->{'image'};

}
# EO sub draw

####################################################################################################

sub debug
{
	my ($self) = @_;
	print "#" x 78, "\n";
	printf "DEBUG SPRITESET <%s> (%sx%s)\n",
		$self->{'id'}, $self->width, $self->height;
	print "#" x 78, "\n";
	foreach my $area ($self->areas)
	{
		print "AREA: ", $area->{'name'}, " ", $area->debug, "\n";
		foreach my $sprite ($area->children)
		{
			print "  SPRITE: ", $sprite->debug, "\n";
		}
	}
	print "#" x 75, "\n";

}

####################################################################################################
####################################################################################################
1;