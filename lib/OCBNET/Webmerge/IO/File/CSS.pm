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
use OCBNET::Webmerge qw();
################################################################################
use OCBNET::CSS3::Regex::Base qw($re_url);
################################################################################
use OCBNET::CSS3::URI qw(wrapUrl exportUrl fromUrl);
################################################################################

################################################################################
# embed imported files and partials
# partials are not wrapped inside urls
################################################################################

OCBNET::Webmerge::options('embed-css-imports', 'embed-css-imports!', 1);
OCBNET::Webmerge::options('embed-css-partials', 'embed-css-partials!', 1);
OCBNET::Webmerge::options('embed-scss-imports', 'embed-css-imports!', 1);
OCBNET::Webmerge::options('embed-scss-partials', 'embed-css-partials!', 1);

################################################################################
# rebase urls within file types
# once this feature is disabled, it shall
# be disabled for all further includes
################################################################################

OCBNET::Webmerge::options('rebase-urls-in-css', 'rebase-urls-in-css!', 1);
OCBNET::Webmerge::options('rebase-urls-in-scss', 'rebase-urls-in-scss!', 0);

################################################################################

sub export
{

	# get arguments
	my ($output, $data) = @_;

	# call export on parent class
	$output->SUPER::export($data);

	# get new export base dir
	my $base = $output->dirname;
	# my $base = $output->directory;

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
use OCBNET::CSS3::Regex::Base qw($re_import unquot);
################################################################################
use File::Spec::Functions qw(catfile);
use File::Basename qw();

# helper to rebase a url
################################################################################

# sub importURL ($;$) { OCBNET::CSS3::URI->new($_[0], $_[1])->wrap }
# sub exportURL ($;$) { OCBNET::CSS3::URI->new($_[0])->export($_[1]) }

sub resolver
{

	# get arguments
	my ($node, $uri) = @_;

	# parse uri into it's parts
	my ($name, $root) = File::Basename::fileparse($uri);

	foreach my $path (
		catfile($node->directory, $root),
		catfile($node->dirname, $root)
	)
	{
		foreach my $srch ('%s', '_%s', '%s.scss', '_%s.scss')
		{
			if (-e catfile($path, sprintf($srch, $name)))
			{ return catfile($path, sprintf($srch, $name)); }
		}
	}

	return $uri;

}

################################################################################
################################################################################

sub resolve
{

	# get arguments
	my ($node, $data) = @_;

	# embed further includes
	${$data} =~ s/$re_import/

		# location
		my $uri;

		# store match
		my $all = $&;

		# is unwrapped uri
		if (exists $+{uri})
		{
			# load partials by sass order
			$uri = $node->resolver(unquot($+{uri}));
		}
		# or have wrapped url
		elsif (exists $+{url})
		{
			# just unquote uril
			$uri = unquot($+{url});
		}

		# create template to check for specific option according to import type
		my $cfg = sprintf '%%s-%s-%s', 'css', exists $+{uri} ? 'partials' : 'imports';

		# check if we should embed this import
		if ($node->config( sprintf $cfg, 'embed' ))
		{

			# create a new xml input node under the current input node
			my $css = OCBNET::Webmerge::Config::XML::Input::CSS->new($node);
			# only need to set a path to init
			$css->{'attr'}->{'path'} = $uri;
			# embed content
			${$css->read};

		}

		# leave unchanged
		else { $all }

	/ge;
	# EO each @import

	# return reference
	return $data;

}
# EO resolve

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

	# get import base and root
	my $root = $node->webroot;
	my $base = $node->directory;

	# alter all urls to absolute paths (relative to base directory)
	${$data} =~ s/($re_url)/

	wrapUrl(importUrl(fromUrl($1), $base, $root))/ge;

}

################################################################################
################################################################################

sub finalize
{

	# get arguments
	my ($output, $data) = @_;

	# call export on parent class
	$output->import($data);

	# get new export base dir
	my $base = $output->directory;

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