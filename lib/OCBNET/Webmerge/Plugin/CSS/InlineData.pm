################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Plugin::CSS::InlineData;
################################################################################

use strict;
use warnings;

################################################################################

# plugin namespace
my $ns = 'css::inlinedata';

################################################################################
# alter data in-place
################################################################################

sub process
{

	# get arguments
	my ($file, $data) = @_;

}

################################################################################
# called via perl loaded
################################################################################

sub import
{
	# get arguments
	my ($fqns, $node, $webmerge) = @_;
	# register our processor to document
	$node->document->processor($ns, \&process);
}

################################################################################
################################################################################
1;

