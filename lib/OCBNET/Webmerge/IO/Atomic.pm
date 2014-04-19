################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Atomic;
################################################################################
# use base 'OCBNET::Webmerge::Merge';
################################################################################

use strict;
use warnings;

################################################################################
# constructor
################################################################################

sub new
{
	# get arguments
	my ($node, $parent) = @_;
	# create atomic hash
	$node->{'atomic'} = {};
}

################################################################################
# get atomic handle by path
################################################################################

sub parent
{
	# get arguments
	my ($node) = @_;
	# find next scope
	while ($node)
	{
		# abort search in tree
		last if $node->{'atomic'};
		# move node up in tree
		$node = $node->parent;
	}
	# return node
	return $node;
}

sub atomic
{
	# get arguments
	my ($node, $path, $atomic) = @_;
	# set new instance
	if ($atomic)
	{
		# store atomic instance by path
		$node->{'atomic'}->{$path} = $atomic;
	}
	# get instance
	else
	{
		# return atomic node if path exists
		if (exists $node->{'atomic'}->{$path})
		{ return $node->{'atomic'}->{$path}; }
		# get parent atomic scope
		my $parent = parent($node->parent);
		# otherwise call on parent scope
		return $parent->atomic($path) if $parent;
		# or return failure
		return ();
	}
}

sub DESTROY
{
	warn "destroyed";
}

################################################################################
################################################################################
1;