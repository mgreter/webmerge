####################################################################################################
# this is the base class for all children containers
# it can be drawn (is a block) and can have child nodes
####################################################################################################
package OCBNET::Spritesets::Container;
####################################################################################################

use strict;
use warnings;

####################################################################################################

use base 'OCBNET::Spritesets::Block';

####################################################################################################

sub gcf {
  my ($x, $y) = @_;
  ($x, $y) = ($y, $x % $y) while $y;
  return $x;
}

sub lcm {
  return($_[0] * $_[1] / gcf($_[0], $_[1]));
}

sub multigcf {
  my $x = shift;
  $x = gcf($x, shift) while @_;
  return $x;
}

sub multilcm {
  my $x = shift;
  $x = lcm($x, shift) while @_;
  return $x;
}

####################################################################################################

# create a new object
# called from children
# ******************************************************************************
sub new
{

	my ($pckg, $parent) = @_;

	my $self = $pckg->SUPER::new($parent);

	# only for debugging purposes
	$self->{'bg'} = "xc:transparent";

	$self->{'children'} = [];

	return bless $self, $pckg;

}
# EO sub new

####################################################################################################

# getter for all children in list context
# ******************************************************************************
# sub children { return @{$_[0]->{'children'}}; }

####################################################################################################

# add more children to this block
# ******************************************************************************
sub add
{

	my ($self, $child) = @_;

	# add new child to our array
	push(@{$self->{'children'}}, $child);

	# attach ourself as parent
	$child->{'parent'} = $self;

	# return new number of children
	return scalar @{$self->{'children'}};

}
# EO sub add

####################################################################################################

# getter for all children in list context
# ******************************************************************************
sub children { return @{$_[0]->{'children'}}; }

# getter for number of childrens
# ******************************************************************************
sub length { return scalar @{$_[0]->{'children'}}; }

####################################################################################################

# check if this block is empty
# ******************************************************************************
sub empty
{

	# check if the number of children is zero
	return scalar @{$_[0]->{'children'}} == 0;

}
# EO sub empty

####################################################################################################

# layout all child nodes
# updates dimensions and positions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = @_;

	# layout all children
	$_->layout foreach (@{$self->{'children'}});

	# return success
	return $self;

}
# EO sub layout


####################################################################################################

sub scaleX
{
	my ($self) = @_;
	my @factors = (1);
	foreach my $sprite ($self->children)
	{ push(@factors, $sprite->scaleX); }
	my $rv = multilcm(@factors);
	die $rv unless $rv =~ m/^\d+$/;
	return $rv;
}

sub scaleY
{
	my ($self) = @_;
	my @factors = (1);
	foreach my $sprite ($self->children)
	{ push(@factors, $sprite->scaleY); }
	my $rv = multilcm(@factors);
	die $rv unless $rv =~ m/^\d+$/;
	return $rv;
}

####################################################################################################

# draw and return image instance
# ******************************************************************************
sub draw
{

	# get our object
	my ($self) = @_;

	# initialize empty image
	$self->{'image'}->Set(matte => 'True');
	$self->{'image'}->Set(magick => 'png');
	$self->{'image'}->Set(matte => 'True');
	$self->{'image'}->Set(quality => 3);
	$self->{'image'}->Set(size => $self->size);
	$self->{'image'}->ReadImage($self->{'bg'});
	$self->{'image'}->Quantize(colorspace=>'RGB');

	# process all sprites to paint them
	foreach my $sprite (@{$self->{'children'}})
	{
		# draw image on canvas
		$self->{'image'}->Composite(
			compose => 'over',
			y => $sprite->top + $sprite->paddingTop,
			x => $sprite->left + $sprite->paddingLeft,
			image => $sprite->draw
		);
	}
	# EO each sprite

	# return the image instance
	return $self->{'image'};

}
# EO sub draw

####################################################################################################
####################################################################################################
1;