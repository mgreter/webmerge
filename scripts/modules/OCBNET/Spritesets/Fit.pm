###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
# this is a block where all sprites get fitted in
# the smallest available space (see packing module)
####################################################################################################
package OCBNET::Spritesets::Fit;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# a container is also a block
use base 'OCBNET::Spritesets::Container';

####################################################################################################

# calculate positions and dimensions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = @_;

	# do nothing if empty
	return if $self->empty;

	# call layout on all children first
	$_->layout foreach (@{$self->{'children'}});

	# create the packer object for composition
	my $packer = new OCBNET::Packer::2D;

	# fit the rectangles/images
	$packer->fit($self->{'children'});

	# get the dimensions for the image and store on block
	my $width = $self->width = $packer->{'root'}->{'width'};
	my $height = $self->height = $packer->{'root'}->{'height'};

	# process and update rectangles/images
	foreach my $sprite (@{$self->{'children'}})
	{

		# this should never happen, but catch anyway
		# we optimize the input so this should be impossible
		die "fatal: sprite could not be fitted" unless $sprite->{'fit'};

		# update the positions for the sprites
		$sprite->top = $sprite->{'fit'}->{'y'};
		$sprite->left = $sprite->{'fit'}->{'x'};

	}
	# EO each sprite

	# return instance
	return $self;

}
# EO sub layout

####################################################################################################
####################################################################################################
1;
