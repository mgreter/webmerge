################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# XML root is a scope that has no parent
# Stop certain cascading methods here
################################################################################
package OCBNET::Webmerge::Config::XML::Root;
################################################################################
use base qw(
	OCBNET::Webmerge::Config::XML::Scope
	OCBNET::Webmerge::Config::XML::Include
);
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

	# create the ids hash
	$node->{'ids'} = {};

	# return object
	return $node;

}

################################################################################
# access current working dir
################################################################################
use FindBin qw($Bin);
################################################################################

sub directory
{
	# get the directory from the scope config
	my $directory = $_[0]->{'config'}->{'directory'};
	# create absolute path (base relative paths to current directory)
	$_[0]->abspath(defined $directory ? $directory : '.', $Bin);
}

################################################################################
# initial webroot points to working dir
################################################################################

sub webroot
{
	# get the webroot from the scope config
	my $webroot = $_[0]->{'config'}->{'webroot'};
	# create absolute path (base relative paths to current directory)
	$_[0]->abspath(defined $webroot ? $webroot : '.', $_[0]->directory);
}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'ROOT' }

# closest is always me
sub closest { $_[0] }

# document is always me
sub document { $_[0] }

# return passed level
sub level { $_[1] || 0 }

################################################################################
# route some method to include class
# they have implementation in scope class
################################################################################

sub started { shift->OCBNET::Webmerge::Config::XML::Include::started(@_) }
sub confroot { shift->OCBNET::Webmerge::Config::XML::Include::confroot(@_) }
sub filename { shift->OCBNET::Webmerge::Config::XML::Include::filename(@_) }

################################################################################
# route some method to both classes
################################################################################

sub respath
{
	$_[0]->OCBNET::Webmerge::Config::XML::Scope::respath($_[1], $_[2]);
	$_[0]->OCBNET::Webmerge::Config::XML::Include::respath($_[1], $_[2]);
}

################################################################################
################################################################################
1;