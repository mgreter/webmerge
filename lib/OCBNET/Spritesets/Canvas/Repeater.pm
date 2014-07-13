###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# static helper functions for canvas
####################################################################################################
package OCBNET::Spritesets::Canvas::Repeater;
####################################################################################################

use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $OCBNET::Spritesets::Canvas::Repeater = "0.9.0"; }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions to be exported
BEGIN { our @EXPORT = qw(repeater); }

####################################################################################################

# draw repeating sprites
# ******************************************************************************
sub repeater
{

	# get our object
	my ($self) = shift;

	# process all possible areas
	foreach my $area ($self->areas)
	{

		# ignore area if it's empty
		next if $area->empty;

		# get our own dimensions
		my $width = $self->width;
		my $height = $self->height;

		##########################################################
		# draw repeating patterns on the canvas
		##########################################################

		if (

			$area->isa('OCBNET::Spritesets::Fit') ||
			$area->isa('OCBNET::Spritesets::Edge') ||
			$area->isa('OCBNET::Spritesets::Stack')
		)
		{

			# paint the repeatings
			# process all sprites on edge
			foreach my $sprite ($area->children)
			{

				# get the sprite dimensions
				my $sprite_width = $sprite->width;
				my $sprite_height = $sprite->height;

				# get the offset on the canvas
				my $offset = $sprite->offset();

				# get offset position of inner sprite image
				my $left = $offset->{'x'} + $sprite->paddingLeft;
				my $top = $offset->{'y'} + $sprite->paddingTop;

				# no sprite must repeat in both directions
				# XXX - maybe move this check to a better place
				if ($sprite->isRepeatX && $sprite->isRepeatY)
				{ die "fatal error: cannot repeat in both directions"; }

				# is repeating on x axis
				if ($sprite->isRepeatX)
				{

					# declare boundary vars
					my ($lower_x, $upper_x);

					# check if sprite is fixed
					if ($sprite->isFixedX)
					{
						# get the lower boundary
						$lower_x = $offset->{'x'};
						# sum up outer width and lower boundary
						$upper_x = $lower_x + $sprite->outerWidth;
					}
					# sprite has flexible width
					else
					{
						# go behind the left edge
						$lower_x = - $sprite_width;
						# and draw over the right edge
						$upper_x = $width + $sprite_width;
					}
					# EO if isFixedX

					# draw the repeating patterns on the left side of the original drawn sprite
					for (my $i = $left - $sprite_width; $i > $lower_x - $sprite_width; $i -= $sprite_width)
					{

						# optional crop offset
						my $crop_offset = 0;

						# get original sprite image
						my $image = $sprite->{'image'};

						# we have to crop the image as we
						# otherwise may paint into another
						# confined sprite on the canvas
						if ($i < $lower_x)
						{
							# calculate the crop offset
							$crop_offset = $lower_x - $i;
							# calculate the new width after cropping
							my $crop_width = $sprite->width - $crop_offset;
							# create a clone of the sprite
							$image = $image->clone;
							# crop the cloned image
							$image->Crop(
								width => $crop_width,
								height => $sprite->height,
								x => $crop_offset, y => 0
							);
						}
						# EO if needs cropping

						# draw image on canvas
						$self->{'image'}->Composite(
							y => $top,
							image => $image,
							compose => 'over',
							x => $i + $crop_offset
						);

					}
					# EO each repeat on the left

					# draw the repeating patterns on the right side of the original drawn sprite
					for (my $i = $left + $sprite_width; $i < $upper_x; $i += $sprite_width)
					{

						# optional crop offset
						my $crop_offset = 0;

						# get original sprite image
						my $image = $sprite->{'image'};

						# we have to crop the image as we
						# otherwise may paint into another
						# confined sprite on the canvas
						if ($i + $sprite_width > $upper_x)
						{
							# calculate the crop offset
							$crop_offset = $upper_x - $i;
							# create a clone of the sprite
							$image = $image->clone;
							# crop the cloned image
							$image->Crop(
								x => 0, y => 0,
								width => $crop_offset,
								height => $sprite->height
							);
						}

						# draw image on canvas
						$self->{'image'}->Composite(
							y => $top, x => $i,
							compose => 'over',
							image => $image
						);

					}
					# EO each repeat on the right

				}
				# is repeating on y axis
				elsif ($sprite->isRepeatY)
				{

					# declare boundary vars
					my ($lower_y, $upper_y);

					# check if sprite is fixed
					if ($sprite->isFixedY)
					{
						# get the lower boundary
						$lower_y = $offset->{'y'};
						# sum up outer height and lower boundary
						$upper_y = $lower_y + $sprite->outerHeight;
					}
					# sprite has flexible height
					else
					{
						# go behind the top edge
						$lower_y = - $sprite_height;
						# and draw over the bottom edge
						$upper_y = $height + $sprite_height;
					}
					# EO if isFixedY

					# draw the repeating patterns on the top side of the original drawn sprite
					for (my $i = $top - $sprite_height; $i > $lower_y - $sprite_height; $i -= $sprite_height)
					{

						# optional crop offset
						my $crop_offset = 0;

						# get original sprite image
						my $image = $sprite->{'image'};

						# we have to crop the image as we
						# otherwise may paint into another
						# confined sprite on the canvas
						if ($i < $lower_y)
						{
							# calculate the crop offset
							$crop_offset = $lower_y - $i;
							# calculate the new width after cropping
							my $crop_height = $sprite->height - $crop_offset;
							# create a clone of the sprite
							$image = $image->clone;
							# crop the cloned image
							$image->Crop(
								height => $crop_height,
								width => $sprite->width,
								y => $crop_offset, x => 0
							);
						}

						# draw image on canvas
						$self->{'image'}->Composite(
							x => $left,
							image => $image,
							compose => 'over',
							y => $i + $crop_offset
						);

					}
					# EO each repeat on the top

					# draw the repeating patterns on the bottom side of the original drawn sprite
					for (my $i = $top + $sprite_height; $i < $upper_y; $i += $sprite_height)
					{

						# optional crop offset
						my $crop_offset = 0;

						# get original sprite image
						my $image = $sprite->{'image'};

						# we have to crop the image as we
						# otherwise may paint into another
						# confined sprite on the canvas
						if ($i + $sprite_height > $upper_y)
						{

							# calculate the crop offset
							$crop_offset = $upper_y - $i;
							# create a clone of the sprite
							$image = $image->clone;
							# crop the cloned image
							$image->Crop(
								x => 0, y => 0,
								height => $crop_offset,
								width => $sprite->width,
							);
						}

						# draw image on canvas
						$self->{'image'}->Composite(
							x => $left, y => $i,
							compose => 'over',
							image => $image
						);
					}
					# EO each repeat on the bottom

				}

			}
			# EO each sprite

		}
		# EO if fit/edge/stack

	}
	# EO each area

	# return success
	return $self;

}
# EO sub repeater

####################################################################################################
####################################################################################################
1;
