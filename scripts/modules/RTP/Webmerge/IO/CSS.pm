###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::IO::CSS;
###################################################################################################
# http://www.w3.org/TR/CSS21/syndata.html#uri
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# parse urls out of the css file
# do a lousy match for better performance
our $re_url = qr/url\(\s*[\"\']?((?!data:)[^\)]+?)[\"\']?\s*\)/x;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::IO::CSS::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our variables to be exported
BEGIN { our @EXPORT = qw(incCSS readCSS importCSS exportCSS writeCSS); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw($re_url wrapURL); }

###################################################################################################

# import webmerge io file reader and writer
use RTP::Webmerge::IO qw(readfile writefile);

# import local webroot path
use RTP::Webmerge::Path qw(dirname exportURI importURI);

###################################################################################################

# wrap url for css
# also makes it canonical
sub wrapURL
{

	# get uri
	my ($uri) = @_;

	# escape apostrophes
	$uri =~ s/\'/\\\'/g;

	# replace windows backslashes
	# with correct forward slashes
	$uri =~ s/\\/\//g if $^O eq "MSWin32";

	# wrap and return escaped uri
	return sprintf('url(\'%s\')', $uri);

}
# EO wrapURL

###################################################################################################


###################################################################################################

# include a css file
# resolve import statements
# normalize uris to webroot
sub incCSS
{

	# get input variables
	my ($cssfile, $config) = @_;

	# read complete css file
	my $data = readfile($cssfile);

	# die with an error message that css file is not found
	die "css import <$cssfile> could not be read: $!\n" unless $data;

	# change all web uris in the stylesheet to absolute local paths
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(importURI($1, dirname($cssfile), $config))/egm;

	# resolve all css imports and include the stylesheets (recursive resolve url paths)
	${$data} =~ s/\@import\s+$re_url/${incCSS($1, $config)}/gme if $config->{'import-css'};

	# return scalar
	return $data;

}
# EO sub incCSS

###################################################################################################

# read a css file from the disk
# normalize uris to absolute web uris
sub readCSS
{

	# get input variables
	my ($cssfile, $config) = @_;

	# read and normalize the stylesheet
	my $data = incCSS($cssfile, $config);

	# resolve all local paths in the stylesheet to web uris
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(exportURI($1, undef))/egm;

	# return scalar
	return $data;

}
# EO sub readCSS

###################################################################################################

# import the final stylesheet
# normalize uris to absolute local paths
sub importCSS
{

	# get input variables
	my ($data, $cssfile, $config) = @_;

	# change all web uris in the stylesheet to absolute local paths
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(importURI($1, undef, $config))/egm;

	# return as string
	return $data;

}
# EO importCSS

###################################################################################################

# export a CSS stylesheets
# normalize urls to web uris
sub exportCSS
{

	# get input variables
	my ($file, $data, $config) = @_;

	# change all absolute local paths to web uris
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(exportURI($1, dirname($file)))/egm;

	# return success
	return 1;

}
# EO sub exportCSS

###################################################################################################

# write a css file to the disk
sub writeCSS
{

	# get input variables
	my ($path, $data, $config) = @_;

	# call io function to write the file atomically
	return writefile($path, $data, $config->{'atomic'}, 1)

}
# EO sub writeCSS

###################################################################################################

# extend the configurator
use RTP::Webmerge qw(@initers);

# register initializer
push @initers, sub
{

	# get input variables
	my ($config) = @_;

	# include imported css files
	$config->{'import-css'} = 1;

	# should we use absolute urls
	# otherwise includes will be relative
	# for this option we need to webroot path
	$config->{'absoluteurls'} = 0;

	# return additional get options attribute
	return (
		'import-css!' => \ $config->{'cmd_import-css'},
		'absoluteurls!' => \ $config->{'cmd_absoluteurls'}
	);

};
# EO plugin initer

###################################################################################################
###################################################################################################
1;
