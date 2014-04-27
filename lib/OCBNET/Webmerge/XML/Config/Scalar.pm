	################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::XML::Config::Scalar;
################################################################################
use base qw(OCBNET::Webmerge::XML::Config);
################################################################################

use strict;
use warnings;

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'CONFVAR' }

################################################################################
# error messages
################################################################################

my $err_nested = "config tags do not allow any nested tags\n";

################################################################################
# webmerge xml parser implementation
################################################################################

sub started
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# push node to the stack array
	$node->SUPER::started($webmerge);
	# nested config tags are not supported
	die $err_nested if exists $webmerge->{'scalar'};
	# connect scalar by key of the connected hash to parser
	$webmerge->{'scalar'} = \$webmerge->{'config'}->{$node->tag};
}

sub ended
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# store data into the connected scalar
	${$webmerge->{'scalar'}} = $node->{'data'};
	# unconnect the config scalar
	delete $webmerge->{'scalar'};
	# pop node off the stack array
	$node->SUPER::ended($webmerge);
}

################################################################################
################################################################################
1;