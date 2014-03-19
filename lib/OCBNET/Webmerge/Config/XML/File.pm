################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::File;
################################################################################
use base 'OCBNET::Webmerge::Config::XML::Node';
################################################################################

use strict;
use warnings;

################################################################################
# upgrade into specific input input class
################################################################################

sub started
{
	# get arguments
	my ($node, $webmerge) = @_;
	# get type by looking for closest parent node
	my $type = $node->closest(qr/^(?:optimize)$/)->tag;
	# invoke parent class method
	$node->SUPER::started($webmerge);
	# bless into the specific input class
	bless $node, join('::', __PACKAGE__, ucfirst $type);
}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'FILE' }

################################################################################
################################################################################
1;