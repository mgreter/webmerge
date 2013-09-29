###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# this block stacks the sprites vertically
# or horizontally together (and aligned)
####################################################################################################
package OCBNET::Spritesets::Stack;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# a container is also a block
use base 'OCBNET::Spritesets::Container';

####################################################################################################

# create a new object
# ******************************************************************************
sub new
{

	# get package name, parent and options
	my ($pckg, $parent, $stack_vert, $align_opp) = @_;

	# get object by calling super class
	my $self = $pckg->SUPER::new($parent);

	# align the the oppositioning side?
	$self->{'align-opp'} = $align_opp;

	# stack vertically or horizontally?
	$self->{'stack-vert'} = $stack_vert;

	# return object
	return $self;

}

####################################################################################################

# getter methods for the specific options
# ******************************************************************************
sub alignOpp { return $_[0]->{'align-opp'}; }
sub stackVert { return $_[0]->{'stack-vert'}; }

####################################################################################################

# calculate the dimensions and inner positions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = @_;

	$self->SUPER::layout;

	# process all sprites in this edge
	foreach my $sprite ($self->children)
	{


		# only left/top edge
		if (not $self->alignOpp)
		{
			# this is the left edge
			if ($self->stackVert)
			{
				# sprite must not repeat in x
				if (not $sprite->isRepeatX)
				{
					#$sprite->paddingLeft = 0;
					#$sprite->paddingRight = 0;
				}
			}
			# this is the top edge
			else
			{
				# sprite must not repeat in y
				if (not $sprite->isRepeatY)
				{
					#$sprite->paddingTop = 0;
					#$sprite->paddingBottom = 0;
				}
			}
		}
		# EO if left/top
	}
	# EO each sprite

	# declare positions
	my ($top, $left) = (0, 0);

	# declare dimensions
	my ($width, $height) = (0, 0);

	# process all sprites for layout
	foreach my $sprite ($self->children)
	{

		# get the sprite outer dimensions
		my $sprite_width = $sprite->outerWidth;
		my $sprite_height = $sprite->outerHeight;

		# stack sprites vertically
		if ($self->stackVert)
		{
			# increase the stack height
			$height += $sprite_height;
			# search biggest sprite width
			if ($width < $sprite_width)
			{ $width = $sprite_width; }
		}
		# or stack sprites horizontally
		else
		{
			# increase the stack width
			$width += $sprite_width;
			# search biggest sprite height
			if ($height < $sprite_height)
			{ $height = $sprite_height; }
		}

		# store sprite position
		$sprite->left = $left;
		$sprite->top = $top;

		# increase the offset
		if ($self->stackVert)
		{ $top += $sprite_height; }
		else { $left += $sprite_width; }

	}
	# EO each sprite

	# store dimensions
	$self->width = $width;
	$self->height = $height;

	# return here if no alignment is set
	return $self unless $self->alignOpp;

	# process all sprites for alignment
	foreach my $sprite (@{$self->{'children'}})
	{
		# stack sprites vertically
		if ($self->stackVert)
		{
			# align this sprite to the oppositioning side
			$sprite->left = $self->outerWidth - $sprite->outerWidth;
		}
		# or stack sprites horizontally
		else
		{
			# align this sprite to the oppositioning side
			$sprite->top = $self->outerHeight - $sprite->outerHeight;
		}
	}

	# call and return base method
	return $self;

}
# EO sub layout

####################################################################################################
####################################################################################################
1;