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
	my ($file, $mode) = @_;
	# get path for node
	my $path = $file->path;
	# open the filehandle in raw mode
	my $fh = $file->SUPER::open($mode);
	# sniff the encoding for the css file
	my $encoding = sniff_encoding($fh, $path);
	# store sniffed encoding on file node
	$file->{'encoding'} = $encoding if $encoding;
	# put a debug message to the console about the encoding
	# print "open css with encoding: ", $file->{'encoding'}, "\n";
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
	my ($file, $data) = @_;
	# check if we have it cached
	if (exists $file->{'sheet'})
	{ return $file->{'sheet'}; }
	# create a new stylesheet
	my $sheet = OCBNET::CSS3->new;
	# parse the passed data or read from file
	$sheet->parse(${$data || $file->content});
	# store to cache and return sheet
	return $file->{'sheet'} = $sheet;

}

################################################################################
# invalidate the cached sheet
################################################################################

sub revert
{
	# shift context
	my $file = shift;
	# call parent class
	$file->SUPER::revert(@_);
	# remove cached items
	delete $file->{'sheet'};
}

sub commit
{
	# shift context
	my $file = shift;
	# call parent class
	$file->SUPER::revert(@_);
	# remove cached items
	delete $file->{'sheet'};
}

################################################################################
################################################################################
1;