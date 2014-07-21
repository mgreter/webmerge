################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Root is a scope that has no parent
# Stop certain cascading methods here
################################################################################
package OCBNET::Webmerge::Tree::Root;
################################################################################
use base qw(OCBNET::Webmerge::Object);
################################################################################
use base qw(OCBNET::Webmerge::Tree::Scope);
################################################################################

use strict;
use warnings;

################################################################################
# object mixin initialisation
################################################################################
require OCBNET::Webmerge::Tree::Doc;
################################################################################

sub initialize
{

	# get input arguments
	my ($node, $parent) = @_;

	# print initialization for now
	# print "init ", __PACKAGE__, " $node\n";

	# create the document object as the ultimate parent
	$node->{'doc'} = OCBNET::Webmerge::Tree::Doc->new;

}

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'ROOT' }

# we are root
sub root { $_[0] }

# stop level counting
sub level { $_[1] || 0 }

# return the main document
sub document { $_[0]->{'doc'} }

# return the document as parent
sub parent { $_[0]->document }

# check if we are looking for ourself
sub hasParent { return $_[0] eq $_[1] }

################################################################################
################################################################################
1;