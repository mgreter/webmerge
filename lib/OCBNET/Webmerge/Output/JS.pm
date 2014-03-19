################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Output::JS;
################################################################################
# use base 'OCBNET::Webmerge::IO::Input';
################################################################################

use strict;
use warnings;

################################################################################
# render output context
################################################################################
use Encode qw(encode);
################################################################################

sub render
{
	# get arguments
	my ($node) = @_;
	# get list of all outputs
	my $parent = $node->parent;
	# get list of all input blocks
	my @suffix = $parent->find('suffix');
	my @prepend = $parent->find('prepend');
	my @input = $parent->find('input');
	my @append = $parent->find('append');
	my @prefix = $parent->find('prefix');
	# init variables
	my $data = "";
	# just join all css inputs
	$data .= ${$_->read} foreach @suffix;
	$data .= ${$_->read} foreach @prepend;
	$data .= ${$_->read} foreach @input;
	$data .= ${$_->read} foreach @append;
	$data .= ${$_->read} foreach @prefix;
	# encode data into requested encoding
	$data = encode($node->{'encoding'}, $data);
	# return scalar ref
	return \ $data;
}

################################################################################
################################################################################
1;