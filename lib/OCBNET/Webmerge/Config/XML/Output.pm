################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Output;
################################################################################
use base qw(
	OCBNET::Webmerge::Config::XML::Node
	OCBNET::Webmerge::IO::File
);
################################################################################
require OCBNET::Webmerge::Config::XML::Output::JS;
require OCBNET::Webmerge::Config::XML::Output::CSS;
require OCBNET::Webmerge::Config::XML::Output::HTML;
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

	# call new for additional class initialization
	$node->OCBNET::Webmerge::IO::File::new($parent);

	# return object
	return $node;

}

################################################################################
# some common attribute getters
################################################################################

sub target { $_[0]->attr('target') || 'join' }
# sub process { $_[0]->attr('process') }

################################################################################
# upgrade into specific input input class
################################################################################

sub started
{
	# get arguments
	my ($node, $webmerge) = @_;
	# get type by looking for closest parent node
	my $type = $node->closest(qr/^(?:css|js)$/)->tag;
	# invoke parent class method
	$node->SUPER::started($webmerge);
	# bless into the specific input class
	bless $node, join('::', __PACKAGE__, uc $type);
}

################################################################################
# return absolute path for the given input file
################################################################################

sub path { return File::Spec->join($_[0]->directory, $_[0]->attr('path')); }
sub dpath { return File::Spec->join($_[0]->directory, $_[0]->attr('path')); }

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'OUTPUT' }

################################################################################
################################################################################
1;