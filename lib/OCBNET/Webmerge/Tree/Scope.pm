################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Scope is a node that connects to a config scope
# Config scopes inherit settings from parent scopes
# Scopes offer atomic file writes/reads (commit/revert)
################################################################################
package OCBNET::Webmerge::Tree::Scope;
################################################################################
use base qw(OCBNET::Webmerge::Object);
################################################################################
use base qw(OCBNET::Webmerge::Tree::Atomic);
################################################################################

use strict;
use warnings;

################################################################################
# object mixin initialisation
################################################################################

sub initialize
{

	# get input arguments
	my ($node, $parent) = @_;

	# print initialization for now
	# print "init ", __PACKAGE__, " $node\n";

	# create the config hash
	$node->{'config'} = {};

}

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'SCOPE' }

# return ourself
sub scope { $_[0] }

################################################################################
# return program setting or config
################################################################################
use OCBNET::Webmerge qw(isset %values %defaults);
################################################################################

sub setting
{
	# command line options have the highest order
	return $values{$_[1]} if isset $values{$_[1]};
	# get configuration for current scope
	my $rv = $_[0]->SUPER::setting($_[1]);
	# return config if valid or use default
	return isset $rv ? $rv : $defaults{$_[1]};
}

################################################################################
# implement non walking accessors
################################################################################

sub webdir { $_[0]->{'config'}->{'webroot'} }
sub basedir { $_[0]->{'config'}->{'directory'} }
sub workdir { $_[0]->{'config'}->{'directory'} }

################################################################################
################################################################################
1;