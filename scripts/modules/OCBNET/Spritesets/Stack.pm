####################################################################################################
# this block stacks the sprites vertically
# or horizontally together (and aligned)
####################################################################################################
package OCBNET::Spritesets::Stack;
####################################################################################################

use strict;
use warnings;

####################################################################################################

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

	$self->{'opposite'} = $align_opp;
	$self->{'vertical'} = $stack_vert;

	# align the the oppositioning side?
	$self->{'align-opp'} = $align_opp;

	# stack vertically or horizontally?
	$self->{'stack-vert'} = $stack_vert;

	# return object
	return $self;

}

####################################################################################################

sub alignOpp { return $_[0]->{'align-opp'}; }
sub stackVert { return $_[0]->{'stack-vert'}; }

####################################################################################################

# calculate the dimensions and inner positions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = @_;

	# declare positions
	my ($top, $left) = (0, 0);

	# declare dimensions
	my ($width, $height) = (0, 0);

	# process all sprites for layout
	foreach my $sprite ($self->children)
	{

		# get the dimensions
		my $w = $sprite->outerWidth; # ToDo: padding
		my $h = $sprite->outerHeight; # ToDO: padding

		if ($sprite->isRight)
		{
			# $sprite->paddingLeft = 0;
		}

		# stack sprites vertically
		if ($self->stackVert)
		{
			# increase the height and check for max width
			$height += $h; $width = $w if $width < $w;
		}
		# or stack sprites horizontally
		else
		{
			# increase the width and check for max height
			$width += $w; $height = $h if $height < $h;
		}

		# store sprite position
		$sprite->left = $left;
		$sprite->top = $top;

		# increase the offset
		if ($self->stackVert)
		{ $top += $sprite->outerHeight; }
		else { $left += $sprite->outerWidth; }

	}
	# EO each sprite

	# store dimensions
	$self->width = $width;
	$self->height = $height;

	# process all sprites for alignment
	foreach my $sprite (@{$self->{'children'}})
	{
		# stack sprites vertically
		if ($self->stackVert)
		{
			# align this sprite to the oppositioning side
			$sprite->left = $self->outerWidth - $sprite->outerWidth if $self->alignOpp;
		}
		# or stack sprites horizontally
		else
		{
			# align this sprite to the oppositioning side
			$sprite->top = $self->outerHeight - $sprite->outerHeight if $self->alignOpp;
		}
	}

	# success
	return $self;

}
# EO sub layout

####################################################################################################

sub draw
{

	# get our object
	my ($self) = @_;

	# call super class
	$self->SUPER::draw;

	# return the image instance
	return $self->{'image'};

}
# EO sub draw

####################################################################################################
####################################################################################################
1;