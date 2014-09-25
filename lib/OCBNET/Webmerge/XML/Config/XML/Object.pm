	################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::XML::Config::XML::Object;
################################################################################
use base qw(OCBNET::Webmerge::XML::Config);
################################################################################

use strict;
use warnings;

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'CONFXMLOBJ' }

################################################################################
# error messages
################################################################################

my $err_nested = "config: xml object does not allow nested tags\n";

################################################################################
# webmerge xml parser implementation
################################################################################

sub started
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# push node to the stack array
	$node->SUPER::started($webmerge);
	# check for operating modus
	if (exists $webmerge->{'array'})
	{
		# append a new slot on to the array
		push @{$webmerge->{'array'}}, $node;
		# connect scalar by key of the connected array to parser
		$webmerge->{'scalar'} = $webmerge->{'array'}->[-1];
	}
	else
	{
		# nested config tags are not supported
		die $err_nested if exists $webmerge->{'scalar'};
		# connect scalar by key of the connected hash to parser
		$webmerge->{'scalar'} = $webmerge->{'config'}->{$node->tag};
	}

}

sub ended
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# store data into the connected scalar
	%{$webmerge->{'scalar'}} = %{$node};
	# unconnect the config scalar
	delete $webmerge->{'scalar'};
	# pop node off the stack array
	$node->SUPER::ended($webmerge);
}

################################################################################
################################################################################
1;