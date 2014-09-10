	################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::XML::Config::Array;
################################################################################
use base qw(OCBNET::Webmerge::XML::Config);
################################################################################

use strict;
use warnings;

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'CONFARR' }

################################################################################
# webmerge xml parser implementation
################################################################################

sub started
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# push node to the stack array
	$node->SUPER::started($webmerge);
	# create a new empty array for additional scalars
	unless (exists $webmerge->{'config'}->{$node->tag})
	{ $webmerge->{'config'}->{$node->tag} = [] }
	# connect scalar by key of the connected hash to parser
	$webmerge->{'array'} = $webmerge->{'config'}->{$node->tag};
}

sub ended
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# store data into the connected scalar
	# ${$webmerge->{'scalar'}} = $node->{'data'};
	# unconnect the config array
	delete $webmerge->{'array'};
	# pop node off the stack array
	$node->SUPER::ended($webmerge);
}

sub classByTag
{
	# only allow scalars inside arrays (so far)
	'OCBNET::Webmerge::XML::Config::Scalar'
}

################################################################################
################################################################################
1;