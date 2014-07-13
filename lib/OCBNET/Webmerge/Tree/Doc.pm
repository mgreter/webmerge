################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Tree::Doc;
################################################################################
use base qw(OCBNET::Webmerge::Object);
################################################################################
use OCBNET::Webmerge::Tree::Atomic;
################################################################################

use strict;
use warnings;

################################################################################
# object mixin initialisation
################################################################################

sub initialize
{

	# get input arguments
	my ($document, $parent) = @_;

	# print initialization for now
	# print "init ", __PACKAGE__, " $node\n";

	# create the ids hash
	$document->{'ids'} = {};

	# store all atomic handles
	$document->{'atomic'} = {};

	# registered procceses for doc
	$document->{'processors'} = {};

}

################################################################################
# get node by id (or undef if not found)
################################################################################

sub getById { $_[0]->{'ids'}->{$_[1]} }

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'DOC' }

# return the tag name
sub tag { '[DOC]' }

# return the same number
sub level { $_[1] }
sub respath { $_[1] }

# have no more parent
sub parent { undef }

# we are alway closest
sub closest { undef }

################################################################################
# stop the tree cascade
################################################################################

sub root { $_[0] }
sub scope { $_[0] }
sub document { $_[0] }

# fake the interface, add children raw for now
sub children { @{$_[0]->{'children'} || []} }

################################################################################
# implement atomic
################################################################################

sub atomic
{

	# get input arguments
	my ($doc, $path, $handle) = @_;

	# make as unique as possible
	$path = $doc->respath($path);

	# set new instance
	if (scalar(@_) > 2)
	{
		die "asd" unless $handle;
		# store atomic instance by path
		$doc->{'atomic'}->{$path} = $handle;
	}

	# get instance
	else
	{
		# return atomic doc if path exists
		if (defined $doc->{'atomic'}->{$path})
		{ return $doc->{'atomic'}->{$path}; }
	}

	# return handle
	return $handle;

}

################################################################################
# basic IO
################################################################################

sub readfile { die "readfile" }
sub writefile { die "writefile" }

################################################################################
# register some default configs
################################################################################
use OCBNET::Webmerge qw(options %longopts %defaults %values);
################################################################################
use File::Spec::Functions qw(catfile);
################################################################################

# define basic options
# ******************************************************************************
options('man', '!', 0);
options('opts', '!', 0);
options('help', '|?!', 0);

# a configfile is always a good idea
# ******************************************************************************
options('configfile', '|f=s', catfile('conf', 'webmerge.conf.xml'));

################################################################################
# return program setting or config
################################################################################
use OCBNET::Webmerge qw(isset);
################################################################################

sub setting
{
	# command line options have the highest order
	return $values{$_[1]} if isset $values{$_[1]};
	# get configuration for current scope
	my $rv = $_[0]->{'config'}->{$_[1]};
	# return config if valid or use default
	return isset $rv ? $rv : $defaults{$_[1]};
}

################################################################################
# return config or program setting on outer
# will always go back to root for evaluation
################################################################################

sub option { &setting }
sub config { &setting }

################################################################################
# implement final working path access
################################################################################
use File::Spec::Functions qw(rel2abs);
################################################################################
use Cwd qw(cwd); use FindBin qw($Bin);
################################################################################

my $cwd = rel2abs(cwd);
my $Bin = rel2abs($Bin);

################################################################################
# return absolute paths
################################################################################

sub bindir { $Bin }
sub workdir { $cwd }

sub webdir { $_[0]->workdir }
sub incdir { $_[0]->workdir }
sub confdir { $_[0]->workdir }
sub basedir { $_[0]->workdir }

################################################################################
# this defines the internal directory layout
################################################################################
use File::Spec::Functions qw(catfile);
################################################################################

sub extdir { catfile($_[0]->bindir, '..') }

################################################################################
# get or set processors
################################################################################

sub processor
{

	# get arguments (most optional)
	my ($webmerge, $name, $fn) = @_;

	# has a function
	if (scalar(@_) > 2)
	{
		# register the processor by name
		$webmerge->{'processors'}->{$name} = $fn;
	}
	# name is given
	elsif (scalar(@_) > 1)
	{
		# return the processor by name
		$webmerge->{'processors'}->{$name};
	}
	else
	{
		# return the hash ref
		$webmerge->{'processors'};
	}

}

################################################################################
################################################################################
1;