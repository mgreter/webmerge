################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge;
################################################################################
use base OCBNET::Webmerge::Config::XML::Root;
################################################################################
use OCBNET::Webmerge::Config::XML;
################################################################################

use strict;
use warnings;

################################################################################
# constructor
################################################################################

sub new
{

	# get input arguments
	my ($pkg, $parent) = @_;

	# create a new node hash object
	my $node = $pkg->SUPER::new($parent);

	# create the config hash
	$node->{'processors'} = {};

	# return object
	return $node;

}

################################################################################
# get or set processors
################################################################################

sub processor
{

	# get arguments (most optional)
	my ($webmerge, $name, $fn) = @_;

	# has a function
	if (scalar(@_) > 2)
	{
		# register the processor by name
		$webmerge->{'processors'}->{$name} = $fn;
	}
	# name is given
	elsif (scalar(@_) > 1)
	{
		# return the processor by name
		$webmerge->{'processors'}->{$name};
	}
	else
	{
		# return the hash ref
		$webmerge->{'processors'};
	}

}

################################################################################
# load a config file
################################################################################

sub load
{

	# get arguments
	my ($webmerge, $configfile) = @_;

	# create a new parser object (throw away)
	my $parser = OCBNET::Webmerge::Config::XML->new;

	# parse the config file and fill webmerge config tree
	return $parser->parse_file($configfile, $webmerge);

}

################################################################################
################################################################################
1;
