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
sub file233
{
die "Hi";
}

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

# sub file { shift->OCBNET::Webmerge::Config::XML::Include::file(@_) }
# sub path { shift->OCBNET::Webmerge::Config::XML::Include::path(@_) }
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
# everything should have root as a parent
################################################################################

sub hasParent
{
	return $_[0] eq $_[1];
}

################################################################################
# return a list of nodes that are not children of any other node
################################################################################

sub roots
{
	my @roots;
	# remove root
	my $root = shift;
	# process the list from behind
	my $n = scalar(@_); while ($n--)
	{
		# status variable
		my $has_parent = 0;
		# process the list from behind
		my $i = scalar(@_); while ($i--)
		{
			# dont test yourself
			next if $i == $n;
			# check if the node has a known parent
			$has_parent = $_[$n]->hasParent($_[$i]);
			# abort the loop now
			last if $has_parent;
		}
		# only collect nodes that have no parent
		push @roots, $_[$n] unless $has_parent;
	}
	# return nodes
	return @roots;
}

################################################################################
################################################################################
1;