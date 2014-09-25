################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# XML config is just a node holding all the
# configuration variables, we will automatically
# put them to the scope which lies closest to us
################################################################################
package OCBNET::Webmerge::XML::Config;
################################################################################
use base qw(OCBNET::Webmerge::Include);
use base qw(OCBNET::Webmerge::XML::Tree::Node);
################################################################################
require OCBNET::Webmerge::XML::Config::Scalar;
require OCBNET::Webmerge::XML::Config::Array;
################################################################################
require OCBNET::Webmerge::XML::Config::XML::Object;
require OCBNET::Webmerge::XML::Config::XML::Array;
################################################################################

use strict;
use warnings;

################################################################################
# register additional xml tags
################################################################################

$OCBNET::Webmerge::XML::parser{'config'} = __PACKAGE__;

################################################################################
# plugin namespace
################################################################################

my $ns = 'OCBNET::Webmerge::Plugin';

################################################################################
# base hook
################################################################################

our %classes;

################################################################################
# accessor methods
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
	$webmerge->{'config'} = $node->scope->{'config'};
	# push node to the stack array
	$node->SUPER::started($webmerge);
}

sub ended
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# unconnect the config hash
	delete $webmerge->{'config'};
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
# so far we use hardcoded config tags for anything else than scalars
# will need to make this configurable to allow plugins to use arrays
################################################################################

sub classByTag
{
	return $classes{$_[1]} if exists $classes{$_[1]};
	return 'OCBNET::Webmerge::XML::Config::Scalar'
}

################################################################################
################################################################################
1;