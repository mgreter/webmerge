################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::CRC;
################################################################################
use base OCBNET::Webmerge::IO::File;
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::Webmerge qw();
################################################################################

sub new
{

	# get input arguments
	my ($pkg, $parent) = @_;

	# create a new node hash object
	my $node = bless { 'parent' => $parent, 'children' => [] }, $pkg;

	# call new for additional class initialization
	$node->OCBNET::Webmerge::IO::File::init($parent);

	push @{$parent->{'children'}}, $node;

	# return object
	return $node;

}

sub path { join('.', $_[0]->parent->path, 'md5') }

sub parent { $_[0]->{'parent'} }




sub logFile {}

sub collect {}

################################################################################
# return debug path
################################################################################

sub dpath { substr($_[0]->path, - 45) }
sub children { @{$_[0]->{'children'} || []} }

################################################################################
use File::Basename qw();
################################################################################

sub dirname { File::Basename::dirname($_[0]->path) }
sub basename { File::Basename::basename($_[0]->path) }
sub parsefile { File::Basename::basename($_[0]->path) }

################################################################################
################################################################################
1;

