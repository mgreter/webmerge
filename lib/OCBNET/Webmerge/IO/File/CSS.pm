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
use OCBNET::CSS3::Regex::Base qw($re_url);
################################################################################
use OCBNET::CSS3::URI qw(wrapUrl exportUrl fromUrl);
################################################################################

sub export
{

	# get arguments
	my ($output, $data) = @_;

	# call export on parent class
	$output->SUPER::export($data);

	# get new export base dir
	my $base = $output->dirname;

	# alter all urls to paths relative to the base directory
	${$data} =~ s/($re_url)/wrapUrl(exportUrl(fromUrl($1), $base, 0))/ge;

}

################################################################################

# define the template for the script includes
# don't care about doctype versions, dev only
our $css_include_tmpl = '@import url(\'%s\');' . "\n";

################################################################################
# generate a css include (@import)
# add support for data or reference id
################################################################################

sub include
{

	# get arguments
	my ($input, $output) = @_;

	# get a unique path with added fingerprint
	# is guess target is always dev here, or is it?
	my $path = $input->fingerprint($output->target);

	# return the script include string
	return sprintf($css_include_tmpl, $path);

}

################################################################################
# helper to rebase a url
################################################################################

# sub importURL ($;$) { OCBNET::CSS3::URI->new($_[0], $_[1])->wrap }
# sub exportURL ($;$) { OCBNET::CSS3::URI->new($_[0])->export($_[1]) }



################################################################################
# import the css content
# resolve urls to abs paths
################################################################################
use OCBNET::CSS3::Regex::Base qw($re_url);
################################################################################
use OCBNET::CSS3::URI qw(wrapUrl importUrl fromUrl);
################################################################################

sub import
{

	# get arguments
	my ($node, $data) = @_;

	# otherwise import format
	$node->logFile('import');

	# get import base dir
	my $base = $node->dirname;

	# alter all urls to absolute paths (relative to base directory)
	${$data} =~ s/($re_url)/wrapUrl(importUrl(fromUrl($1), $base))/ge;

}

################################################################################
################################################################################

sub finalize
{

	# get arguments
	my ($output, $data) = @_;

	# call export on parent class
	$output->SUPER::export($data);

	# get new export base dir
	my $base = $output->webroot;

	# alter all urls to paths relative to the base directory
	${$data} =~ s/($re_url)/wrapUrl(exportUrl(fromUrl($1), $base, 1))/ge;

}

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
	$file->encoding = $encoding if $encoding;
	# put a debug message to the console about the encoding
	# print "open css with encoding: ", $file->encoding, "\n";
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
	$sheet->parse(${$data || $file->contents});
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
	$file->SUPER::commit(@_);
	# remove cached items
	delete $file->{'sheet'};
}

################################################################################
################################################################################
1;