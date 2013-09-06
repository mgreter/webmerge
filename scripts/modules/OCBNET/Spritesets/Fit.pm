###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
# this is a block where all sprites get fitted in
# the smallest available space (see packaging)
####################################################################################################
package OCBNET::Spritesets::Fit;
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

	# get package name and parent
	my ($pckg, $parent) = @_;

	# get object by calling super class
	my $self = $pckg->SUPER::new($parent);

	# return object
	return $self;

}
# EO new

####################################################################################################

# calculate positions and dimensions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = @_;

	# do nothing if empty
	return if $self->empty;

	# create the packer object for composition
	my $packer = new OCBNET::Spritesets::Packing();

	foreach my $sprite (@{$self->{'children'}})
	{
		$sprite->{'width'} = $sprite->outerWidth;
		$sprite->{'height'} = $sprite->outerHeight;
	}

	# fit the rectangles/images
	$packer->fit($self->{'children'});

	# get the dimensions for the image and store on block
	my $width = $self->{'w'} = $packer->{'root'}->{'width'};
	my $height = $self->{'h'} = $packer->{'root'}->{'height'};

	# process and update rectangles/images
	foreach my $sprite (@{$self->{'children'}})
	{

		# this should never happen, but catch anyway
		# we optimize the input so this should be impossible
		die "fatal: sprite could not be fitted" unless $sprite->{'fit'};

		# update the positions for the sprites
		$sprite->{'x'} = $sprite->{'fit'}->{'x'};
		$sprite->{'y'} = $sprite->{'fit'}->{'y'};

	}
	# EO each sprite

	# return success
	return $self;

}
# EO sub layout


####################################################################################################
1;
