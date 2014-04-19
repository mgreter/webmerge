################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Input;
################################################################################
use base 'OCBNET::Webmerge::Config::XML::Node';
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

sub path { return $_[0]->abspath($_[0]->attr('path'), $_[0]->directory); }
sub dpath { return $_[0]->abspath($_[0]->attr('path'), $_[0]->directory); }

################################################################################
use File::Basename qw();
################################################################################

sub dirname { File::Basename::dirname(shift->path, @_) }
sub basename { File::Basename::basename(shift->path, @_) }
sub fileparse { File::Basename::fileparse(shift->path, @_) }

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT' }

# abort exection
sub execute { 1 }

################################################################################
################################################################################
1;