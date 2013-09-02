####################################################################################################
# static helper functions for canvas
####################################################################################################
package OCBNET::Spritesets::Canvas::Layout;
####################################################################################################

use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $OCBNET::Spritesets::Canvas::Layout = "0.70"; }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions to be exported
BEGIN { our @EXPORT = qw(layout); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw($factors); }

####################################################################################################

# private helper function
# returns all prime factors
# ******************************************************************************
our $factors = sub
{

	# hold all factors
	my @primes;

	# get number to factorize
	my ($number) = @_;

	# loop from 2 up to number
	for ( my $y = 2; $y <= $number; $y ++ )
	{
		# skip if not a factor
		next if $number % $y;
		# divide by factor found
		$number /= $y;
		# store found factor
		push(@primes, $y);
		# restart from 2
		redo;
	}

	# sort the prime factors
	return sort @primes;

};
# EO priv sub factors

####################################################################################################
use List::MoreUtils qw/ uniq /;

# least common multiplier
sub lcm
{
	my $product = 1; $product *= $_
		foreach uniq grep { $_ != 0 }
			map { $factors->($_) } @_;
	return $product;
}

####################################################################################################

# layout all child nodes
# updates dimensions and positions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = @_;

	$self->distribute();

	##########################################################
	# CALL LAYOUT ON AREAS
	##########################################################

	foreach my $sprite (@{$self->{'corner-lt'}->{'children'}})
	{
		# $sprite->{'margin-left'} = $sprite->{'padding-left'};
		# $sprite->{'margin-top'} = $sprite->{'padding-top'};
		$sprite->{'padding-left'} = 0;
		$sprite->{'padding-top'} = 0;
	}

	foreach my $sprite (@{$self->{'corner-lb'}->{'children'}})
	{
		# $sprite->{'margin-left'} = $sprite->{'padding-left'};
		# $sprite->{'margin-bottom'} = $sprite->{'padding-bottom'};
		$sprite->{'padding-left'} = 0;
		$sprite->{'padding-bottom'} = 0;
	}

	foreach my $sprite (@{$self->{'corner-rt'}->{'children'}})
	{
		# $sprite->{'margin-right'} = $sprite->{'padding-right'};
		# $sprite->{'margin-top'} = $sprite->{'padding-top'};
		$sprite->{'padding-right'} = 0;
		$sprite->{'padding-top'} = 0;
	}

	foreach my $sprite (@{$self->{'corner-rb'}->{'children'}})
	{
		# $sprite->{'margin-right'} = $sprite->{'padding-right'};
		# $sprite->{'margin-bottom'} = $sprite->{'padding-top'};
		$sprite->{'padding-right'} = 0;
		$sprite->{'padding-bottom'} = 0;
	}

	foreach my $sprite (@{$self->{'edge-l'}->{'children'}})
	{
		next if $sprite->isRepeatX;
		next if $sprite->isRepeatY;
		# $sprite->{'margin-left'} = $sprite->{'padding-left'};
		$sprite->{'padding-left'} = 0;
	}
	foreach my $sprite (@{$self->{'edge-t'}->{'children'}})
	{
		next if $sprite->isRepeatY;
		next if $sprite->isRepeatX;
		# $sprite->{'margin-top'} = $sprite->{'padding-top'};
		$sprite->{'padding-top'} = 0;
		$sprite->{'padding-bottom'} = 0;
	}
	foreach my $sprite (@{$self->{'stack-l'}->{'children'}})
	{
		next if $sprite->isRepeatX;
		# $sprite->{'margin-left'} = $sprite->{'padding-left'};
		$sprite->{'padding-left'} = 0;
		$sprite->{'padding-right'} = 0;
	}
	foreach my $sprite (@{$self->{'stack-t'}->{'children'}})
	{
		next if $sprite->isRepeatY;
		# $sprite->{'margin-top'} = $sprite->{'padding-top'};
		$sprite->{'padding-top'} = 0;
		$sprite->{'padding-bottom'} = 0;
	}

	# layout all children
	foreach my $area (@{$self->{'areas'}})
	{
			# layout the sub area
			$self->{$area}->layout;
	}

	##########################################################
	# GET MULTIPLIERS FOR DIMENSIONS AND REPEATING
	##########################################################

	use List::MoreUtils qw/ uniq /;

	# declare repating arrays
	my (@repeat_x, @repeat_y);

	foreach my $area (@{$self->{'areas'}})
	{
		foreach my $sprite (@{$self->{$area}->{'children'}})
		{
			if ($sprite->{'repeat-x'} && $sprite->{'repeat-y'})
			{ die "fatal: cannot repeat in both directions"; }
			elsif ($sprite->{'repeat-x'} && $sprite->isFlexibleX)
			{ push(@repeat_x, $factors->($sprite->{'w'})); }
			elsif ($sprite->{'repeat-y'} && $sprite->isFlexibleY)
			{ push(@repeat_y, $factors->($sprite->{'h'})); }
			# if ($sprite->{'scale-x'} && $sprite->{'scale-x'} != 1)
			# { push(@repeat_x, $factors->($sprite->{'scale-x'})); }
			# if ($sprite->{'scale-y'} && $sprite->{'scale-y'} != 1)
			# { push(@repeat_y, $factors->($sprite->{'scale-y'})); }
		}
	}

	# make factors unique
	@repeat_x = uniq @repeat_x;
	@repeat_y = uniq @repeat_y;

	# create the products for the common repeating size
	my $repeat_x = 1; $repeat_x *= $_ foreach @repeat_x;
	my $repeat_y = 1; $repeat_y *= $_ foreach @repeat_y;

	##########################################################
	# GET LIMITS FROM SNAPPED ELEMENTS
	##########################################################

	my $col1_snap_w = lcm(
		$self->{'edge-l'}->scaleX,
		$self->{'stack-l'}->scaleX,
		$self->{'corner-lb'}->scaleX,
		$self->{'corner-lt'}->scaleX
	);
	my $row1_snap_h = lcm(
		$self->{'edge-t'}->scaleY,
		$self->{'stack-t'}->scaleY,
		$self->{'corner-rt'}->scaleY,
		$self->{'corner-lt'}->scaleY
	);

	my $col2_snap_w = lcm(
		$self->{'stack-t'}->scaleX,
		$self->{'middle'}->scaleX,
		$self->{'stack-b'}->scaleX
	);
	my $row2_snap_h = lcm(
		$self->{'stack-l'}->scaleY,
		$self->{'middle'}->scaleY,
		$self->{'stack-r'}->scaleY
	);

	my $col3_snap_w = lcm($self->{'edge-t'}->scaleX);
	my $row3_snap_h = lcm($self->{'edge-l'}->scaleY);
	my $col4_snap_w = lcm($self->{'edge-b'}->scaleX);
	my $row4_snap_h = lcm($self->{'edge-r'}->scaleY);

	my $col_snap_last_w = lcm(
		$self->{'edge-r'}->scaleX,
		$self->{'stack-r'}->scaleX,
		$self->{'corner-rb'}->scaleX,
		$self->{'corner-rt'}->scaleX
	);

	my $row_snap_last_h = lcm(
		$self->{'edge-b'}->scaleY,
		$self->{'stack-b'}->scaleY,
		$self->{'corner-lb'}->scaleY,
		$self->{'corner-rb'}->scaleY
	);

	my $col_snap_w = lcm(
		$col1_snap_w,
		$col2_snap_w,
		$col3_snap_w,
		$col4_snap_w,
		$col_snap_last_w
	);

	my $row_snap_h = lcm(
		$row1_snap_h,
		$row2_snap_h,
		$row3_snap_h,
		$row4_snap_h,
		$row_snap_last_h
	);

	# sub snap { $_[0] += 20 - $_[0] % (20); }
	sub snap { my $rest = $_[0] % $_[1]; $_[0] += $rest ? $_[1] - $rest : 0; }

	##########################################################
	# GET LIMITS FROM SNAPPED ELEMENTS
	##########################################################

	use List::Util qw[min max];

	my $col1_w = max(
		$self->{'edge-l'}->outerWidth,
		$self->{'stack-l'}->outerWidth,
		$self->{'corner-lb'}->outerWidth,
		$self->{'corner-lt'}->outerWidth
	);

	my $row1_h = max(
		$self->{'edge-t'}->outerHeight,
		$self->{'stack-t'}->outerHeight,
		$self->{'corner-rt'}->outerHeight,
		$self->{'corner-lt'}->outerHeight
	);

	snap ($col1_w, $col1_snap_w);
	snap ($row1_h, $row1_snap_h);

	my $col2_w = max(
		$self->{'stack-t'}->outerWidth,
		$self->{'middle'}->outerWidth,
		$self->{'stack-b'}->outerWidth
	);
	my $row2_h = max(
		$self->{'stack-l'}->outerHeight,
		$self->{'middle'}->outerHeight,
		$self->{'stack-r'}->outerHeight
	);

	snap ($col2_w, $col2_snap_w);
	snap ($row2_h, $row2_snap_h);

	my $col3_w = $self->{'edge-t'}->outerWidth;
	my $row3_h = $self->{'edge-l'}->outerHeight;
	my $col4_w = $self->{'edge-b'}->outerWidth;
	my $row4_h = $self->{'edge-r'}->outerHeight;

	snap ($col3_w, $col3_snap_w);
	snap ($row3_h, $row3_snap_h);
	snap ($col4_w, $col4_snap_w);
	snap ($row4_h, $row4_snap_h);

	my $col_last_w = max(
		$self->{'edge-r'}->outerWidth,
		$self->{'stack-r'}->outerWidth,
		$self->{'corner-rb'}->outerWidth,
		$self->{'corner-rt'}->outerWidth
	);

	my $row_last_h = max(
		$self->{'edge-b'}->outerHeight,
		$self->{'stack-b'}->outerHeight,
		$self->{'corner-lb'}->outerHeight,
		$self->{'corner-rb'}->outerHeight
	);

	my $col1_x = $col1_w;
	my $row1_y = $row1_h;

	snap ($col1_x, $col1_snap_w);
	snap ($row1_y, $row1_snap_h);

	my $col2_x = $col1_x + $col2_w;
	my $row2_y = $row1_y + $row2_h;

	snap ($col2_x, $col2_snap_w);
	snap ($row2_y, $row2_snap_h);

	# make sure both sides will fit our repeating pattern for all
	# this can blow up the sprite by quite some factor if your images
	# dimensions have lots of different factors in it, if they are all
	# of about the same size this should work quite well
	$col2_x += $repeat_x - ($col2_x + $col4_w + $col_last_w) % $repeat_x;
	$row2_y += $repeat_y - ($row2_y + $row4_h + $row_last_h) % $repeat_y;

	snap ($col2_x, $col2_snap_w);
	snap ($row2_y, $row2_snap_h);

	my $col3_x = $col2_x + $col3_w;
	my $col4_x = $col3_x + $col4_w;

	snap ($col3_x, $col3_snap_w);
	snap ($col4_x, $col4_snap_w);

	my $row3_y = $row2_y + $row3_h;
	my $row4_y = $row3_y + $row4_h;

	snap ($row3_y, $row3_snap_h);
	snap ($row4_y, $row4_snap_h);

	##########################################################
	# CALCULATE LAYOUT
	##########################################################

	my $width = 0;
	my $height = 0;

	##########################################################
	# we have 13 areas, so 26 positions to set
	##########################################################

	# leave the first row in place (8)
	$self->{'corner-lt'}->top = 0;
	$self->{'corner-lt'}->left = 0;
	$self->{'stack-t'}->top = 0;
	$self->{'stack-l'}->left = 0;
	$self->{'edge-t'}->top = 0;
	$self->{'edge-l'}->left = 0;
	$self->{'corner-rt'}->top = 0;
	$self->{'corner-lb'}->left = 0;

	##########################################################

	# move the second row aways (6)
	$self->{'stack-l'}->top = $row1_y;
	$self->{'middle'}->top = $row1_y;
	$self->{'stack-r'}->top = $row1_y;
	$self->{'stack-t'}->left = $col1_x;
	$self->{'middle'}->left = $col1_x;
	$self->{'stack-b'}->left = $col1_x;

	##########################################################

	# move the third row aways (4)
	$self->{'edge-l'}->top = $row2_y;
	$self->{'edge-r'}->top = $row3_y;
	$self->{'edge-t'}->left = $col2_x;
	$self->{'edge-b'}->left = $col3_x;

	##########################################################

	$width = $self->width = $col4_x + $col_last_w;
	$height = $self->height = $row4_y + $row_last_h;

	snap ($width, $col_snap_w);
	snap ($height, $row_snap_h);

	##########################################################

	# move the fourth row aways (8)
	# align them to the right / bottom
	$self->{'corner-rb'}->top = $self->outerHeight - $self->{'corner-rb'}->outerHeight;
	$self->{'corner-rb'}->left = $self->outerWidth - $self->{'corner-rb'}->outerWidth;
	$self->{'stack-b'}->top = $self->outerHeight - $self->{'stack-b'}->outerHeight;
	$self->{'stack-r'}->left = $self->outerWidth - $self->{'stack-r'}->outerWidth;
	$self->{'edge-b'}->top = $self->outerHeight - $self->{'edge-b'}->outerHeight;
	$self->{'edge-r'}->left = $self->outerWidth - $self->{'edge-r'}->outerWidth;
	$self->{'corner-lb'}->top = $self->outerHeight - $self->{'corner-lb'}->outerHeight;
	$self->{'corner-rt'}->left = $self->outerWidth - $self->{'corner-rt'}->outerWidth;

	##########################################################
	# LAYOUT ALL WIDGETS
	##########################################################
	if (0)
	{

		# layout all children
		foreach my $area (@{$self->{'areas'}})
		{

			# position the area
			$self->{$area}->left = $width;
			$self->{$area}->top = $height;

			# ignore area if it's empty
			next if $self->{$area}->empty;

			# layout the sub area
			$self->{$area}->layout;

			unless(defined $self->{$area}->height)
			{
				die $self->{$area};
			}

			# increase the dimensions
			$width += $self->{$area}->width;
			$height += $self->{$area}->height;

		}

		# shift around some containers for correct layout
		$self->{'stack-t'}->{'x'} += $self->{'stack-l'}->{'w'};
		$self->{'stack-l'}->{'x'} -= $self->{'stack-t'}->{'w'};
		$self->{'stack-b'}->{'x'} -= $self->{'stack-r'}->{'w'};
		$self->{'stack-r'}->{'x'} += $self->{'stack-b'}->{'w'};

		# store widget size
		$self->width = $width;
		$self->height = $height;

	}

	if (0)
	{

	# declare repating arrays
	my (@repeat_x, @repeat_y);

	foreach my $area (@{$self->{'areas'}})
	{
		foreach my $sprite (@{$self->{$area}->{'children'}})
		{
			if ($sprite->{'repeat-x'} && $sprite->{'repeat-y'})
			{ die "fatal: cannot repeat in both directions"; }
			elsif ($sprite->{'repeat-x'})
			{ push(@repeat_x, $sprite->{'w'}); }
			elsif ($sprite->{'repeat-y'})
			{ push(@repeat_y, $sprite->{'h'}); }
		}
	}

	use List::MoreUtils qw/ uniq /;

	my ($repeat_x, $repeat_y) = (0, 0);

	if (scalar @repeat_x)
	{
		@repeat_x = uniq map { $factors->($_) } map { split(/\s+/, $_) } @repeat_x;
		my $product = 1; $product *= $_ foreach @repeat_x; $repeat_x += $product while $repeat_x < $self->width;
	}
	if (scalar @repeat_y)
	{
		@repeat_y = uniq map { $factors->($_) } map { split(/\s+/, $_) } @repeat_y;
		my $product = 1; $product *= $_ foreach @repeat_y; $repeat_y += $product while $repeat_y < $self->height;
	}

	# store the new size of the outer layout
	$self->width = $repeat_x if $self->width < $repeat_x;
	$self->height = $repeat_y if $self->height < $repeat_y;

	}

	# layout all children
	foreach my $area (@{$self->{'areas'}})
	{

		# ignore area if it's empty
		next if $self->{$area}->empty;

		# do a re layout only for stacked (repeating) elements
		next unless $self->{$area}->isa('OCBNET::Spritesets::Stack');

		# re-align the sub area
		if ($self->{$area}->alignOpp)
		{
			if ($self->{$area}->stackVert)
			{ $self->{$area}->{'x'} = $self->{'w'} - $self->{$area}->{'w'}; }
			else { $self->{$area}->{'y'} = $self->{'h'} - $self->{$area}->{'h'}; }
		}


	}

	# return success
	return $self;

}
# EO sub layout

####################################################################################################
####################################################################################################
1;
