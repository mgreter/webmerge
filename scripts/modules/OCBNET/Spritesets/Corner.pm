###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
package OCBNET::Spritesets::Corner;
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
	my ($pckg, $parent, $right, $bottom) = @_;

	# get object by calling super class
	my $self = $pckg->SUPER::new($parent);

	# set the options for the corner
	$self->{'is-right'} = $right;
	$self->{'is-bottom'} = $bottom;

	# return object
	return $self;

}

####################################################################################################

sub isRight { return $_[0]->{'is-right'}; }
sub isBottom { return $_[0]->{'is-bottom'}; }

####################################################################################################

# calculate positions and dimensions
# ******************************************************************************
sub layout
{

	# get our object
	my ($self) = @_;

	# do nothing if empty
	return if $self->empty;

	# check if we really only have one child
	die "illegal state" if $self->length != 1;

	# get the only sprite in the corner
	my $sprite = $self->{'children'}->[0];

	# fix position to zero
	$sprite->{'x'} = 0;
	$sprite->{'y'} = 0;

	# use the dimension of the sprite
	$self->{'w'} = $sprite->outerWidth;
	$self->{'h'} = $sprite->outerHeight;

	# return success
	return $self;

}
# EO sub layout


####################################################################################################
####################################################################################################
1;
