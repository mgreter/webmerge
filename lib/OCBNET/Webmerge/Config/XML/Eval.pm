################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Eval;
################################################################################
use base 'OCBNET::Webmerge::Config::XML::Node';
################################################################################

use strict;
use warnings;

################################################################################
# some accessor methods
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

# return node type
sub type { 'EVAL' }

################################################################################
################################################################################
1;

