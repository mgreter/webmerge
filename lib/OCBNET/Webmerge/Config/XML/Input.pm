################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Input;
################################################################################
use base qw(
	OCBNET::Webmerge::Config::XML::Node
	OCBNET::Webmerge::IO::File
);
################################################################################
require OCBNET::Webmerge::Config::XML::Input::JS;
require OCBNET::Webmerge::Config::XML::Input::CSS;
require OCBNET::Webmerge::Config::XML::Input::HTML;
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

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT' }

sub execute
{

return;
	my $start = $_[0]->read;

	print "read: ", ${$start}, "\n";

	my $count = 1 + ${$start};

	my $atomic1 = $_[0]->write(\ "$count");
	my $atomic2 = $_[0]->write(\ "$count");

	print 'write: ', $atomic1, "\n";
	print 'write: ', $atomic2	, "\n";

	my $content = $_[0]->read;

	print "final: ", ${$content}, "\n";


	# die ;
}

################################################################################
################################################################################
1;