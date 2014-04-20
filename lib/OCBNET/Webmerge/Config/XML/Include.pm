################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# XML root is a scope that has no parent
# Stop certain cascading methods here
################################################################################
package OCBNET::Webmerge::Config::XML::Include;
################################################################################
use base 'OCBNET::Webmerge::Config::XML::Node';
################################################################################

use strict;
use warnings;

################################################################################
# webmerge xml parser implementation
################################################################################

sub started
{
	# get arguments from parser
	my ($node, $webmerge) = @_;
	# invoke parent class method
	my $rv = $node->SUPER::started($webmerge);
	# store the include filename on this node
	$node->{'filename'} = $webmerge->{'filename'};
	# return result
	return $rv;
}

################################################################################
# return information about include scope
################################################################################
use File::Basename qw(dirname);
################################################################################

# return the include filename
sub file233 { $_[0]->{'filename'} }

# return the full include filename
sub filename { $_[0]->abspath($_[0]->{'filename'}) }

# return the base directory of the include
sub confroot { $_[0]->abspath(dirname $_[0]->{'filename'}) }

################################################################################
# return resolved path
################################################################################

sub respath
{
	# get arguments
	my ($node, $path) = @_;
	# resolve some specific placeholders
	$path =~ s/^\{CONF\}/$node->confroot/ei;
	# cascade down to the parent class
	return $node->SUPER::respath($path);
}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INCLUDE' }

################################################################################
################################################################################
1;