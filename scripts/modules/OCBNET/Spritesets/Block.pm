###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# this is the base class for all drawable items
# it can only be drawn and not hold any children
####################################################################################################
package OCBNET::Spritesets::Block;
####################################################################################################

use strict;
use warnings;

# load imagemagick
# use Image::Magick;

####################################################################################################

# create a new object
# called from children
# ***************************************************************************************
sub new
{

	my ($pckg, $parent) = @_;

	my $self = {

		# offset position
		'x' => 0,
		'y' => 0,

		# inner dimesions
		'w' => 0,
		'h' => 0,

		# paddings for the box
		'padding-top' => 0,
		'padding-right' => 0,
		'padding-bottom' => 0,
		'padding-left' => 0,
		# paddings for the box
		# 'margin-top' => 0,
		# 'margin-right' => 0,
		# 'margin-bottom' => 0,
		# 'margin-left' => 0,

		# the parent block node
		'parent' => $parent,

		# create an empty image
		'image' => new Graphics::Magick
		# 'image' => new Image::Magick

	};

	return bless $self, $pckg;

}
# EO sub new

####################################################################################################

# getter and setter methods
# ***************************************************************************************
sub left : lvalue { $_[0]->{'x'} }
sub top : lvalue { $_[0]->{'y'} }
sub width : lvalue { $_[0]->{'w'} }
sub height : lvalue { $_[0]->{'h'} }

# getter and setter methods
# ***************************************************************************************
# sub marginTop : lvalue { $_[0]->{'margin-top'} }
# sub marginLeft : lvalue { $_[0]->{'margin-left'} }
# sub marginRight : lvalue { $_[0]->{'margin-right'} }
# sub marginBottom : lvalue { $_[0]->{'margin-bottom'} }

# getter and setter methods
# ***************************************************************************************
sub paddingTop : lvalue { $_[0]->{'padding-top'} }
sub paddingLeft : lvalue { $_[0]->{'padding-left'} }
sub paddingRight : lvalue { $_[0]->{'padding-right'} }
sub paddingBottom : lvalue { $_[0]->{'padding-bottom'} }

# getter for combined results
# ***************************************************************************************
sub size { return join('x', $_[0]->width, $_[0]->height); }

# getter for outer dimensions
# ***************************************************************************************
sub outerWidth { return $_[0]->width + $_[0]->paddingLeft + $_[0]->paddingRight; }
sub outerHeight { return $_[0]->height + $_[0]->paddingTop + $_[0]->paddingBottom; }

####################################################################################################
sub position { die "change to offset position"; }
####################################################################################################

# return the offset position from parent
# ***************************************************************************************
sub getOffsetPosition
{

	my ($self) = @_;

	return
	{
		'x' => $self->left,
		'y' => $self->top
	};

}
# EO sub offsetPosition

# set the offset position from parent
# ***************************************************************************************
sub setOffsetPosition
{

	my ($self, $x, $y) = @_;

	$self->{'x'} = $x;
	$self->{'y'} = $y;

}
# EO sub setOffsetPosition

####################################################################################################
# setter and getter for position
####################################################################################################

# return absolute position from root
# ***************************************************************************************
sub getPosition
{

	my ($self) = @_;

	my $x = $self->{'x'};
	my $y = $self->{'y'};

	if ($self->{'parent'})
	{
		my $offsetPosition = $self->{'parent'}->getOffsetPosition();
		$x += $offsetPosition->{'x'}; $y += $offsetPosition->{'y'};
	}

	return {
		'x' => $x,
		'y' => $y
	};
}
# EO sub getPosition

####################################################################################################
# some event handlers for drawing
####################################################################################################

# nothing needs to be done
sub layout { return $_[0]; }

####################################################################################################

sub generate
{
	die "implement generate\n";
}

sub redraw
{
	return $_[1];
}

sub calculate
{
	return $_[1];
}

sub draw
{
	# return the image instance
	return $_[0]->{'image'};
}

sub repeat
{
	return 0;
}

sub debug
{

	# get our object
	my ($self) = @_;

	# get absolute position from root
	my $position = $self->getPosition();

	# debug position
	return sprintf(
		'at %s/%s (%sx%s) -> [%s/%s|%s/%s@%s/%s] => %s/%s',
		$self->{'x'}, $self->{'y'},
		$self->{'w'}, $self->{'h'},
		$self->{'padding-left'}, $self->{'padding-top'},
		$self->{'padding-right'}, $self->{'padding-bottom'},
		$self->{'scale-x'} || 1, $self->{'scale-y'} || 1,
		$position->{'x'}, $position->{'y'},
	);

}

####################################################################################################
####################################################################################################
1;