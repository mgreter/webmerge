####################################################################################################
####################################################################################################
package OCBNET::Spritesets::Edge;
####################################################################################################

use strict;
use warnings;

####################################################################################################

use base 'OCBNET::Spritesets::Stack';

####################################################################################################


# create a new object
# ******************************************************************************
sub new
{

	# get package name, parent and options
	my ($pckg, $parent, $stack_vert, $align_opp) = @_;

	# get object by calling super class
	my $self = $pckg->SUPER::new($parent);

	$self->{'opposite'} = $align_opp;
	$self->{'vertical'} = $stack_vert;

	# align the the oppositioning side?
	$self->{'align-opp'} = $align_opp;

	# stack vertically or horizontally?
	$self->{'stack-vert'} = $stack_vert;

	# return object
	return $self;

}

####################################################################################################

sub alignOpp { return $_[0]->{'align-opp'}; }
sub stackVert { return $_[0]->{'stack-vert'}; }

####################################################################################################

# calculate positions and dimensions
# ******************************************************************************
sub layout2
{

	# get our object
	my ($self) = @_;

	# do nothing if empty
	return if $self->empty;

	# return success
	return $self;

}
# EO sub layout


####################################################################################################
####################################################################################################
1;
