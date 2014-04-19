################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File::CSS;
################################################################################
use base OCBNET::Webmerge::IO::File;
################################################################################

use strict;
use warnings;

################################################################################
use IO::CSS qw(sniff_encoding);
################################################################################

sub open
{
	# get arguments
	my ($node, $mode) = @_;
	# get path for node
	my $path = $node->path;
	# open the filehandle in raw mode
	my $fh = $node->SUPER::open($mode);
	# sniff the encoding for the css file
	my $encoding = sniff_encoding($fh, $path);
	# store sniffed encoding on file node
	$node->{'encoding'} = $encoding if $encoding;
	# put a debug message to the console about the encoding
	# print "open css with encoding: ", $node->{'encoding'}, "\n";
	# return filehandle
	return $fh;
}

################################################################################
# return parsed stylesheet
################################################################################
use OCBNET::CSS3;
################################################################################

sub sheet
{

	# get arguments
	my ($node) = @_;
	# check if we have it cached
	if (exists $node->{'sheet'})
	{ return $node->{'sheet'}; }
	# create a new stylesheet
	my $sheet = OCBNET::CSS3->new;
	# parse the content node
	$sheet->parse(${$node->content});
	# store to cache and return sheet
	return $node->{'sheet'} = $sheet;

}

################################################################################
# invalidate the cached sheet
################################################################################

sub revert
{
	# shift context
	my $node = shift;
	# call parent class
	$node->SUPER::revert(@_);
	# remove cached items
	delete $node->{'sheet'};
}

sub commit
{
	# shift context
	my $node = shift;
	# call parent class
	$node->SUPER::revert(@_);
	# remove cached items
	delete $node->{'sheet'};
}

################################################################################
################################################################################
1;