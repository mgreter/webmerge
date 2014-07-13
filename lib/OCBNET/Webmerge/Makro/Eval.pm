################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Makro::Eval;
################################################################################

use strict;
use warnings;

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'MAKRO::EVAL' }

################################################################################
# execute eval
################################################################################

sub execute
{
	# get arguments
	my ($node) = @_;
	# execute code
	eval $node->text;
	# progagate errors
	die $@ if $@;
}

################################################################################
################################################################################
1;

