################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Config;
################################################################################
use base OCBNET::Webmerge::Config::XML::Node;
################################################################################
use OCBNET::Webmerge::Config::XML::Config::Scalar;
################################################################################

use strict;
use warnings;

################################################################################
# plugin namespace
################################################################################

my $ns = 'OCBNET::Webmerge::Plugin';

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'CONFIG' }

# abort execution
sub execute { 1 }

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
	# implement basic plugin system
	if ($node->tag eq "plugin")
	{
		# get module path from node
		if ($node->attr('path'))
		{
			# just try to load the file
			require $node->attr('path');
		}
		# get module name from node
		elsif ($node->attr('module'))
		{
			# get module from attribute
			my $module = $node->attr('module');
			# sanitize module name strictly
			$module =~ s/[^a-zA-Z0-9-_:\.]//g;
			# try to load module from namespace
			# pass our node to import functions
			eval("use $ns\:\:" . $module . ' ($node, $webmerge)');
			# propagate all errors when loading plugins
			die "error loading ", $module, "\n", $@ if $@;
		}
		# EO if module
	}
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