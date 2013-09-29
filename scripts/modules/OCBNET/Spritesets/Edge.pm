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
		if ($self->stackVert)
		{
			if ($self->alignOpp)
			{
				if ($sprite->alignLeft)
				{
					unless ($sprite->isRepeatX)
					{
						$sprite->paddingLeft = 0;
					}
					$sprite->paddingRight = 0;
				}
			}
		}
		else
		{
			if ($sprite->alignTop)
			{
				unless ($sprite->isRepeatY)
				{
					$sprite->paddingTop = 0;
				}
				$sprite->paddingBottom = 0;
			}
		}
	}

	# call stack layout
	$self->SUPER::layout;

	# call and return base method
	return $self;

}
# EO sub layout

####################################################################################################
####################################################################################################
1;
