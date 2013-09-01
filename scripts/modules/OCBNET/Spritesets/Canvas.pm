####################################################################################################
# this is the main canvas or root block to be drawn
# it contains four stacked frames on each side on
# one in the middle where the sprites are fitted
####################################################################################################
package OCBNET::Spritesets::Canvas;
####################################################################################################

use strict;
use warnings;

####################################################################################################

use OCBNET::Spritesets::Canvas::Layout;
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
	$self->{'x'} = 0; $self->{'y'} = 0;

	# initialize the width and the height
	$self->{'w'} = 0; $self->{'h'} = 0;

	# make a copy of our area strings
	$self->{'areas'} = [ @areas ];

	# array with all sprites
	$self->{'sprites'} = [];

	# debug mode variable
	$self->{'debug'} = 0;

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

	# if in debug mode we assign background colors
	# this way you can see what got distributed where
	if ($self->{'debug'})
	{
		$self->{'middle'}->{'bg'} = 'xc:rgba(0, 255, 0, 0.25)';
		$self->{'edge-t'}->{'bg'} = 'xc:rgba(150, 150, 0, 0.25)';
		$self->{'edge-r'}->{'bg'} = 'xc:rgba(150, 150, 0, 0.25)';
		$self->{'edge-b'}->{'bg'} = 'xc:rgba(150, 150, 0, 0.25)';
		$self->{'edge-l'}->{'bg'} = 'xc:rgba(150, 150, 0, 0.25)';
		$self->{'stack-t'}->{'bg'} = 'xc:rgba(150, 0, 150, 0.25)';
		$self->{'stack-r'}->{'bg'} = 'xc:rgba(150, 0, 150, 0.25)';
		$self->{'stack-b'}->{'bg'} = 'xc:rgba(150, 0, 150, 0.25)';
		$self->{'stack-l'}->{'bg'} = 'xc:rgba(150, 0, 150, 0.25)';
		$self->{'corner-lt'}->{'bg'} = 'xc:rgba(0, 150, 150, 0.25)';
		$self->{'corner-rt'}->{'bg'} = 'xc:rgba(0, 150, 150, 0.25)';
		$self->{'corner-lb'}->{'bg'} = 'xc:rgba(0, 150, 150, 0.25)';
		$self->{'corner-rb'}->{'bg'} = 'xc:rgba(0, 150, 150, 0.25)';
	}

	# add the widgets to parent
	foreach my $area (@areas)
	{ $self->SUPER::add($self->{$area}); }

	# reset the children array
	$self->{'children'} = [];

	# return object
	return $self;

}
# EO new

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

sub signed
{
	return $_[0] < 0 ?
		  sprintf('%s', $_[0])
		: sprintf('+%s', $_[0]);
}

sub draw
{

	# get our object
	my ($self) = @_;

	# find out our final dimensions
	# make sure that stacks that are
	# repeating are taken care of

	# initialize empty image
	$self->{'image'}->Set(matte => 'True');
	$self->{'image'}->Set(magick => 'png');
	$self->{'image'}->Set(matte => 'True');
	$self->{'image'}->Set(size => $self->size);
	$self->{'image'}->Set(quality => 3);
	$self->{'image'}->ReadImage($self->{'bg'});
	$self->{'image'}->Quantize(colorspace=>'RGB');
	# print "draw image with ", $self->size, "\n";

	# process all possible areas
	foreach my $area (@areas)
	{

		# ignore area if it's empty
		next if $self->{$area}->empty;

		my $width = $self->width;
		my $height = $self->height;

		# printf "draw %s with %d/%d at %d/%d\n", $area,
		#	$self->{$area}->{'w'}, $self->{$area}->{'h'},
		#	$self->{$area}->{'x'}, $self->{$area}->{'y'};

		# get sprite and position
		#my $sprite = $images->{$area};
		#my $position = $positions->{$area};
		# draw image on canvas
		$self->{'image'}->Composite(
			compose => 'Over',
			x => $self->{$area}->{'x'},
			y => $self->{$area}->{'y'},
			image => $self->{$area}->draw
		);


if (

	$self->{$area}->isa('OCBNET::Spritesets::Fit') ||
	$self->{$area}->isa('OCBNET::Spritesets::Edge') ||
	$self->{$area}->isa('OCBNET::Spritesets::Stack')
)
{

		# paint the repeatings
		# process all sprites on edge
		foreach my $sprite (@{$self->{$area}->{'children'}})
		{

			my $w = $sprite->width;
			my $h = $sprite->height;

			my $position = $sprite->getPosition();

			my $x = $position->{'x'} + $sprite->paddingLeft;
			my $y = $position->{'y'} + $sprite->paddingTop;


			if ($sprite->{'repeat-x'} && $sprite->{'repeat-y'})
			{
				die "fatal: cannot repeat in both directions";
			}
			elsif ($sprite->{'repeat-x'})
			{

				my $lower_x = - $w;
				my $upper_x = $width + $w;

				$lower_x = $position->{'x'} if $sprite->{'enclosed-x'};
				$upper_x = $position->{'x'} + $sprite->outerWidth if $sprite->{'enclosed-x'};

				my $pos_x = $sprite->{'position-x'};
				if ($pos_x=~m/(\-?[0-9]+)px/i)
				{
					# $lower_x -= $1;
					# $upper_x -= $1 + 2;
				}

				for (my $i = $x - $w; $i > $lower_x - $w; $i -= $w)
				{

					my $offset = 0;
					my $image = $sprite->{'image'}->clone;
					if ($i < $lower_x)
					{

						$offset = $lower_x - $i;

						$image = $sprite->{'image'}->clone;
						# draw image on canvas
						$image->Crop(
							width => $sprite->width - $offset,
							height => $sprite->height,
							x => $offset, y => 0
						);
					}

					# draw image on canvas
					$self->{'image'}->Composite(
						compose => 'over',
						x => $i + $offset, y => $y,
						image => $image
					);
				}
				####
				for (my $i = $x + $w; $i < $upper_x; $i += $w)
				{
					my $offset = 0;
					my $image = $sprite->{'image'}->clone;
					if ($i + $w > $upper_x)
					{
						$offset = $upper_x - $i;
						$image = $sprite->{'image'}->clone;
						# draw image on canvas
						$image->Crop(
							width => $offset,
							height => $sprite->height,
							x => 0, y => 0
						);
					}

					# draw image on canvas
					$self->{'image'}->Composite(
						compose => 'over',
						x => $i, y => $y,
						image => $image
					);

					die "what $w ", $image->get('width')," ", ($i + $image->get('width')), " => ", $upper_x
						if $i + $image->get('width') > $upper_x;

				}

			}
			elsif ($sprite->{'repeat-y'})
			{

				my $lower_y = - $h;
				my $upper_y = $height + $h;

				$lower_y = $position->{'y'} if $sprite->{'enclosed-y'};
				$upper_y = $position->{'y'} + $sprite->outerHeight if $sprite->{'enclosed-y'};

				for (my $i = $y - $h; $i > $lower_y - $h; $i -= $h)
				{
					my $offset = 0;
					my $image = $sprite->{'image'};
					if ($i < $lower_y)
					{

						$offset = $lower_y - $i;
						$image = $sprite->{'image'}->clone;
						# draw image on canvas
						$image->Crop(
							width => $sprite->width,
							height => $sprite->height - $offset,
							x => 0, y => $offset
						);
					}
					# draw image on canvas
					$self->{'image'}->Composite(
						compose => 'over',
						x => $x, y => $i + $offset,
						image => $image
					);
				}
				for (my $i = $y + $h; $i < $upper_y; $i += $h)
				{
					my $offset = 0;
					my $image = $sprite->{'image'};
					if ($i + $h > $upper_y)
					{
						$offset = $upper_y - $i;
						# die if $offset < 0;
						$image = $sprite->{'image'}->clone;
						# draw image on canvas
						$image->Crop(
							width => $sprite->width,
							height => $offset,
							x => 0, y => 0
						);
						die if $offset < 0;
					}
					# draw image on canvas
					$self->{'image'}->Composite(
						compose => 'over',
						x => $x, y => $i,
						image => $image
					);
				}
			}

		}

	}

	}
	# EO each area

	# return the image instance
	return $self->{'image'};

}
# EO sub draw

####################################################################################################

sub debug
{
	my ($self) = @_;
	print "#" x 60, "\n";
	print "DEBUG SPRITESET CANVAS\n";
	printf "width: %s, height: %s\n",
		$self->width, $self->height;
	print "#" x 60, "\n";
	foreach my $area (@areas)
	{
		print "AREA: ", $area, " ", $self->{$area}->debug, "\n";
		foreach my $sprite ($self->{$area}->children)
		{
			print "  SPRITE: ", $sprite->debug, "\n";
		}
	}
	print "#" x 60, "\n";

}

####################################################################################################
####################################################################################################
1;