################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Scope is a node that connects to a config scope
# Config scopes inherit settings from parent scopes
# Scopes offer atomic file writes/reads (commit/revert)
################################################################################
package OCBNET::Webmerge::Tree::Atomic;
################################################################################
use base qw(OCBNET::Webmerge::Object);
################################################################################
use base qw(OCBNET::Webmerge::Tree::Node);
################################################################################

use strict;
use warnings;
1;
__DATA__

################################################################################
# object mixin initialisation
################################################################################

sub initialize
{

	# get input arguments
	my ($node, $parent) = @_;

	# print initialization for now
	# print "init ", __PACKAGE__, " $node\n";

	# create atomic hash
	$node->{'atomic'} = {};

}

################################################################################
# get or set atomic file handle by path
################################################################################
use File::Spec::Functions qw(canonpath);
################################################################################

sub atomic
{

	# get input arguments
	my ($node, $path, $handle) = @_;

	# make as unique as possible
	$path = $node->respath($path);

	# set new instance
	if (scalar(@_) > 2)
	{
		# store atomic instance by path
		$node->{'atomic'}->{$path} = $handle;
		$node->document->atomic($path, $handle);
	}

	# get instance
	else
	{
		# return atomic node if path exists
		if (defined $node->{'atomic'}->{$path})
		{ return $node->{'atomic'}->{$path}; }
		# search atomic handle on parents
		return $node->SUPER::atomic($path);
	}

	# return handle
	return $handle;

}

################################################################################
# commit all changes
################################################################################

sub commit
{

	# get arguments
	my ($node) = @_;

	# get the atomic hash from object
	my $atomic = $node->{'atomic'} || {};

	# process all paths in the atomic hash
	foreach my $path (sort keys %{$atomic})
	{
		# get staged handle/object
		my $file = $atomic->{$path};
		# handle commit according to object type
		if (UNIVERSAL::can($file, 'commit')) { $file->commit }
		elsif (UNIVERSAL::can($file, 'close')) { $file->close }
	}

	# return object
	return $node;

}

################################################################################
# revert all changes
################################################################################

sub revert
{

	# get arguments
	my ($node) = @_;

	# get the atomic hash from object
	my $atomic = $node->{'atomic'} || {};

	# process all paths in the atomic hash
	foreach my $path (sort keys %{$atomic})
	{
		# get staged handle/object
		my $file = $atomic->{$path};
		# handle commit according to object type
		if (UNIVERSAL::can($file, 'revert')) { $file->revert }
		elsif (UNIVERSAL::can($file, 'delete')) { $file->delete }
	}

	# call on parent class
	$node->SUPER::revert;

	# return object
	return $node;

}

################################################################################
################################################################################
1;
