###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# static helper functions for canvas
####################################################################################################
package OCBNET::Spritesets::Canvas::Distribute;
####################################################################################################

use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $OCBNET::Spritesets::Canvas::Distribute = "0.70"; }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions to be exported
BEGIN { our @EXPORT = qw(distribute); }

####################################################################################################

# distribute all sprites to areas
# according to their configurations
sub distribute
{

	# get our object
	my ($self) = @_;

	# a sprite that is enclosed can mostly be fitted. It's not
	# unnormal to have some offset for the image, but mostly the
	# container is nearly of the same size as the sprite. In some
	# cases the dev meant to use it left aligned in a big container.
	# then we should handle it as a left aligned image and put it
	# on the edge. This threshold determines when to fit and when
	# to put the sprite on the edge/stack area. Both padding will
	# be counted (outerWidth - width > fit_threshold).
	my $fit_threshold = 50;

	##########################################################

	# reset area childrens (just in case)
	foreach my $area (@{$self->{'areas'}})
	{ $self->{$area}->{'children'} = []; }

	##########################################################

	# reset distributed flag on all sprites
	foreach my $sprite (@{$self->{'sprites'}})
	{ $sprite->{'distributed'} = 0; }

	##########################################################
	# DISTRIBUTERS
	##########################################################

	my @distributers = (

		# distribute one sprite into right bottom corner
		# optimum for non enclosed sprite left/top aligned
		# can remove all paddings and offset from left/top
		[ $self->{'corner-rb'}, 'isRepeating||isRight||isBottom||isFixedX||isFixedY', 1 ],

		# distribute one sprite into right top corner
		# optimum for height enclosed sprite left/bottom aligned
		# can remove height paddings and offset from top
		[ $self->{'corner-rt'}, 'isRepeating||isRight||notBottom||isFixedX', 1 ],

		# distribute one sprite into left bottom corner
		# optimum for width enclosed sprite right/top aligned
		# can remove width paddings and offset from left
		[ $self->{'corner-lb'}, 'isRepeating||notRight||isBottom||isFixedY', 1 ],

		# distribute one sprite into left top corner
		# optimum for enclosed sprite right/bottom aligned
		# can remove paddings and offset from left/top
		[ $self->{'corner-lt'}, 'isRepeating||notRight||notBottom||isFlexibleY||isFlexibleX', 1 ],

		# distribute the smaller items to the packed area to save precious space on the edges
		[ $self->{'middle'}, 'isFlexibleY||isFlexibleX||outerWidth-width>$fit_threshold||outerHeight-height>$fit_threshold' ],

		# distribute sprites into left/top edge
		[ $self->{'stack-l'}, 'isRepeating||notRight||isFlexibleY||isFlexibleX' ],
		[ $self->{'stack-t'}, 'isRepeating||notBottom||isFlexibleY||isFlexibleX' ],
		# distribute sprites into right/bottom edge
		[ $self->{'stack-r'}, 'isRight||isRepeatX||isRepeatY||isFlexibleY' ],
		[ $self->{'stack-b'}, 'isBottom||isRepeatY||isRepeatX||isFlexibleX' ],

		# distribute sprites into the packed center
		[ $self->{'middle'}, 'isFlexibleY||isFlexibleX' ],

		# distribute sprites into edges
		[ $self->{'edge-l'}, 'isRight||isFlexibleY||isRepeatingBoth' ],
		[ $self->{'edge-r'}, 'notRight||isFlexibleY||isRepeatingBoth' ],
		[ $self->{'edge-t'}, 'isBottom||isFlexibleX||isRepeatingBoth' ],
		[ $self->{'edge-b'}, 'notBottom||isFlexibleX||isRepeatingBoth' ],

	);

	##########################################################

	# process all distributers for all areas
	foreach my $distributer (@distributers)
	{

		# get the options for this area distributer
		my ($area, $excludes, $max) = @{$distributer};

		# replace certain keywords to be an actual object call
		$excludes =~ s/\b(?=is|not|width|height|outer)/\$_[0]->/g;

		# eval the condition into a pre-compiled subroutine to call
		$excludes = eval sprintf 'sub { return (%s); };', $excludes;

		# propagate any eval errors
		# not needed but just in case
		die $@ if $@;

		# process each sprite to see if it should be
		# distributed into the currently checked area
		foreach my $sprite (@{$self->{'sprites'}})
		{

			# skip already distributed sprites
			next if $sprite->{'distributed'};

			# check for failed excludes
			next if $excludes->($sprite);

			# add sprite to area
			$area->add($sprite);

			# set the distributed flag
			$sprite->{'distributed'} = 1;

			# check if we have distributed enough sprites
			last if $max && scalar(@{$area->{'children'}}) >= $max;

		}
		# EO each sprite

	}
	# EO each distributer

	##########################################################

	# unsupported sprites
	my $unsupported = 0;

	# check for sprite that have not been distributed
	# there are quite a few configurations that cannot
	# be handled - inform the user about these problems
	foreach my $sprite (@{$self->{'sprites'}})
	{
		next if $sprite->{'distributed'};
		warn sprintf "unsupported: %s : rep(%s/%s), enc(%s/%s), pos(%s/%s)\n",
			substr($sprite->{'filename'}, - 25),
			$sprite->{'repeat-x'}, $sprite->{'repeat-y'},
			$sprite->{'enclosed-x'}, $sprite->{'enclosed-y'},
			$sprite->{'position-x'}, $sprite->{'position-y'};
		$unsupported ++;
	}

	# wait a second make user more
	# aware that some problem exists
	sleep 1 if $unsupported;

}
# EO sub distribute

####################################################################################################
####################################################################################################
1;
