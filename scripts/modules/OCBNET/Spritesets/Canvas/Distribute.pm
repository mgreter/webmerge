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

sub distribute
{

	# get our object
	my ($self) = @_;

	# sprite is fully enclosed
	# means it has a div around with fixed
	# dimensions where it cannot escape from

	my $do_corners = 1;
	my $do_stacks = 1;
	my $do_fits = 1;
	my $do_edges = 1;

	# a sprite that is enclosed can mostly be fitted. It's not
	# unnormal to have some offset for the image, but mostly the
	# container is nearly of the same size as the sprite. In some
	# cases the dev meant to use it left aligned in a big container.
	# then we should handle it as a left aligned image and put it
	# on the edge. This threshold determines when to fit and when
	# to put the sprite on the edge/stack area. Both padding will
	# be counted (outerWidth - width > fit_threshold).
	my $fit_threshold = 75;


	##########################################################

	# reset area childrens (just in case)
	foreach my $area (@{$self->{'areas'}})
	{ $self->{$area}->{'children'} = []; }

	##########################################################

	# reset distributed flag on all sprites
	foreach my $sprite (@{$self->{'sprites'}})
	{ $sprite->{'distributed'} = 0; }

	##########################################################
	# CORNERS
	##########################################################

	sub hasConstrain
	{
		my ($sprite, $constrain) = @_;

		if ($constrain->{'flex'})
		{
			if ($constrain->{'flex'} eq 'x')
			{
				#return 1 if $sprite->isFlexibleY;
			}
			else
			{
				#return 1 if $sprite->isFlexibleX;
			}
		}
		return 0;
	}

	sub addConstrain
	{
		my ($sprite, $constrain) = @_;
		if ($sprite->isFlexibleX)
		{
			$constrain->{'flex'} = 'x';
		}
		if ($sprite->isFlexibleY)
		{
			$constrain->{'flex'} = 'y';
		}
	}

	my $contrain = {};

	if ($do_corners)
	{

		# distribute one sprite into right bottom corner
		# optimum for non enclosed sprite left/top aligned
		foreach my $sprite (@{$self->{'sprites'}})
		{
			last unless $self->{'corner-rb'}->empty;
			next if $sprite->{'distributed'};
			next if $sprite->isRepeating;
			next if $sprite->isRight;
			next if $sprite->isBottom;
			next if $sprite->isFixedX;
			next if $sprite->isFixedY;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'corner-rb'}->add($sprite);
			$sprite->{'distributed'} = 1; last;
		}

		# distribute one sprite into right top corner
		# optimum for non enclosed-x sprite left/bottom aligned
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isRepeating;
			next if $sprite->isRight;
			next if $sprite->notBottom;
			next if $sprite->isFixedX;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'corner-rt'}->add($sprite);
			$sprite->{'distributed'} = 1; last;
		}

		# distribute one sprite into left bottom corner
		# optimum for non enclosed sprite right/top aligned
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isRepeating;
			next if $sprite->notRight;
			next if $sprite->isBottom;
			next if $sprite->isFixedY;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'corner-lb'}->add($sprite);
			$sprite->{'distributed'} = 1; last;
		}

		# distribute one sprite into left top corner
		# optimum for non enclosed sprite right/bottom aligned
		# do not waste this spot for
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isRepeating;
			next if $sprite->notRight;
			next if $sprite->notBottom;
			next if $sprite->isFlexibleY;
			next if $sprite->isFlexibleX;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'corner-lt'}->add($sprite);
			$sprite->{'distributed'} = 1; last;
		}

	}

	##########################################################
	# FITS THAT DO NOT PROFIT FROM BEEING ON THE STACK
	##########################################################

	if ($do_fits)
	{

		# distribute sprites into the fitting area
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isFlexibleY;
			next if $sprite->isFlexibleX;
			# skip here if there is too much space lost
			next if $sprite->outerWidth - $sprite->width > $fit_threshold;
			next if $sprite->outerHeight - $sprite->height > $fit_threshold;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'middle'}->add($sprite);
			$sprite->{'distributed'} = 1; next;
		}

	}

	##########################################################
	# EDGE
	##########################################################

	if ($do_stacks)
	{

		# distribute sprites into bottom edge
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isBottom;
			next if $sprite->isRepeatY;
			next if $sprite->isRepeatX;
			next if $sprite->isFlexibleX;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'stack-b'}->add($sprite);
			$sprite->{'distributed'} = 1; next;
		}

		# distribute sprites into right edge
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isRight;
			next if $sprite->isRepeatX;
			next if $sprite->isRepeatY;
			next if $sprite->isFlexibleY;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'stack-r'}->add($sprite);
			$sprite->{'distributed'} = 1; next;
		}

	}


	if ($do_stacks)
	{
		# distribute sprites into top edge
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isRepeating;
			next if $sprite->notBottom;
			next if $sprite->isFlexibleY;
			next if $sprite->isFlexibleX;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'stack-t'}->add($sprite);
			$sprite->{'distributed'} = 1; next;
		}

		# distribute sprites into left edge
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isRepeating;
			next if $sprite->notRight;
			next if $sprite->isFlexibleY;
			next if $sprite->isFlexibleX;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'stack-l'}->add($sprite);
			$sprite->{'distributed'} = 1; next;
		}

	}
	##########################################################
	# MIDDLE FIT
	##########################################################

	if ($do_fits)
	{

		# distribute sprites into the fitting area
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isFlexibleY;
			next if $sprite->isFlexibleX;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'middle'}->add($sprite);
			$sprite->{'distributed'} = 1; next;
		}

	}


	##########################################################
	# STACK
	##########################################################

	if ($do_edges)
	{

		# distribute sprites into bottom stack
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->notBottom;
			next if $sprite->notFixedX;
			next if $sprite->isRepeatBoth;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'edge-b'}->add($sprite);
			$sprite->{'distributed'} = 1; next;
		}

		# distribute sprites into right stack
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->notRight;
			next if $sprite->notFixedY;
			next if $sprite->isRepeatBoth;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'edge-r'}->add($sprite);
			$sprite->{'distributed'} = 1; next;
		}

		# distribute sprites into left stack
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isRight;
			next if $sprite->notFixedY;
			next if $sprite->isRepeatBoth;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'edge-l'}->add($sprite);
			$sprite->{'distributed'} = 1; next;
		}

		# distribute sprites into top stack
		foreach my $sprite (@{$self->{'sprites'}})
		{
			next if $sprite->{'distributed'};
			next if $sprite->isBottom;
			next if $sprite->notFixedX;
			next if $sprite->isRepeatBoth;
			next if hasConstrain($sprite, $contrain);
			addConstrain($sprite, $contrain);
			$self->{'edge-t'}->add($sprite);
			$sprite->{'distributed'} = 1; next;
		}


	}



	##########################################################

	# distribute one sprite into the fitting area
	foreach my $sprite (@{$self->{'sprites'}})
	{
		next if $sprite->{'distributed'};
		warn sprintf "unsupported: %s : rep(%s/%s), enc(%s/%s), pos(%s/%s)\n",
			substr($sprite->{'filename'}, - 25),
			$sprite->{'repeat-x'},
			$sprite->{'repeat-y'},
			$sprite->{'enclosed-x'},
			$sprite->{'enclosed-y'},
			$sprite->{'position-x'},
			$sprite->{'position-y'};

	}

	# distribute one sprite into the fitting area
	foreach my $sprite (@{$self->{'sprites'}})
	{
		next if $sprite->{'distributed'};
		sleep 1; last; # die "not all sprites distributed";
	}
}


####################################################################################################
####################################################################################################
1;
