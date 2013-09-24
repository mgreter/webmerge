###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# so far the canvas makes the difference between
# an edge and a stack, but leave this file so we
# may move relevant optimizations into here later
####################################################################################################
package OCBNET::Spritesets::Edge;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# a stack is a container is a block
use base 'OCBNET::Spritesets::Stack';

####################################################################################################

# layout the edge
# ******************************************************************************
sub layout
{

	# get instance
	my ($self) = shift;

	# process all sprites in this edge
	foreach my $sprite ($self->children)
	{
		# only left/top edge
		if (not $self->alignOpp)
		{
			# sprite must not repeat at all
			if (not $sprite->isRepeating)
			{
				# this is the left edge
				if ($self->stackVert)
				{
					$sprite->{'padding-left'} = 0;
					$sprite->{'padding-right'} = 0;
				}
				# this is the top edge
				else
				{
					$sprite->{'padding-top'} = 0;
					$sprite->{'padding-bottom'} = 0;
				}
			}
		}
		# EO if left/top
	}
	# EO each sprite

	# call and return base method
	return $self->SUPER::layout(@_);

}
# EO sub layout

####################################################################################################
####################################################################################################
1;
