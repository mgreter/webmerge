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
	$node->OCBNET::Webmerge::IO::File::new($parent);

	push @{$parent->{'children'}}, $node;

	# return object
	return $node;

}

sub parent { $_[0]->{'parent'} }


sub dirname { $_[0]->parent->dirname }

sub export { return $_[1] }
sub process { return $_[1] }
sub checksum { return $_[1] }
sub finalize { return $_[1] }

sub children { @{$_[0]->{'children'}} }

sub logFile {}


sub path
{
	# create path to store checksum of this output
	join('.', $_[0]->parent->path, 'md5');

}

################################################################################
################################################################################
1;

