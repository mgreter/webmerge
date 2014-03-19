################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Config;
################################################################################
use base 'OCBNET::Webmerge::Config::XML::Node';
################################################################################
use OCBNET::Webmerge::Config::XML::Config::Scalar;
################################################################################

use strict;
use warnings;

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'CONFIG' }

################################################################################
# webmerge xml parser implementation
################################################################################

sub started
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# connect scope config hash to parser hash
	$webmerge->{'hash'} = $node->scope->{'config'};
	# push node to the stack array
	$node->SUPER::started($webmerge);
}

sub ended
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# unconnect the config hash
	delete $webmerge->{'hash'};
	# pop node off the stack array
	$node->SUPER::ended($webmerge);
}

################################################################################
# anything below is a scalar (fills scope config automatically)
################################################################################

sub classByTag { 'OCBNET::Webmerge::Config::XML::Config::Scalar' }

################################################################################
################################################################################
################################################################################
1;