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

# parse different string types
our $re_apo = qr/(?:[^\'\\]+|\\.)*/s;
our $re_quot = qr/(?:[^\"\\]+|\\.)*/s;

# parse urls out of the css file
# do a lousy match for better performance
our $re_url = qr/url\(\s*(?:
	\s*\"(?!data:)(?<url>$re_quot)\" |
	\s*\'(?!data:)(?<url>$re_apo)\' |
	(?![\"\'])\s*(?!data:)(?<url>[^\)]*)
)\s*\)/xi;

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
use RTP::Webmerge::Path qw(exportURI importURI $directory);

# import base filename functions
use RTP::Webmerge::Path qw(dirname basename);

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

# read a css file from the disk
# normalize uris to absolute web uris
sub readCSS
{

	# get input variables
	my ($cssfile, $config) = @_;

	# create new css input object (partly parse the css file)
	# this should be extended to support all css operations
	my $input = RTP::Webmerge::Input::CSS->new($cssfile, $config);

	if (wantarray)
	{
		return [
			$input->render,
			[
				map { $_->{'path'} }
				$input->assets
			]
		]
	}

	# render stylesheet (resolve assets)
	return $input ? $input->render  : undef;

}
# EO sub readCSS

###################################################################################################

# import the final stylesheet
# normalize uris to absolute local paths
sub importCSS
{

	# get input variables
	my ($data, $cssfile, $config) = @_;

	# check for config if we should do anything
	return $data unless $config->{'rebase-urls-in-css'};

	# change all web uris in the stylesheet to absolute local paths
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(importURI($+{url}, $directory, $config))/egm;

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
	my ($cssfile, $data, $config) = @_;

	# change all absolute local paths to web uris
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(exportURI($+{url}, dirname($cssfile)))/egm;

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

	# should we use absolute urls
	# otherwise includes will be relative
	# for this option we need the webroot
	$config->{'absoluteurls'} = 0;

	# embed imported files and partials
	# partials are not wrapped inside urls
	$config->{'embed-css-imports'} = 1;
	$config->{'embed-css-partials'} = 1;
	$config->{'embed-scss-imports'} = 1;
	$config->{'embed-scss-partials'} = 1;

	# rebase urls within file types
	# once this feature is disabled, it shall
	# be disabled for all further includes
	$config->{'rebase-urls-in-css'} = 1;
	$config->{'rebase-urls-in-scss'} = 0;

	# return additional get options attribute
	return (
		'absoluteurls!' => \ $config->{'cmd_absoluteurls'},
		'embed-css-imports!' => \ $config->{'cmd_embed-css-imports'},
		'embed-css-partials!' => \ $config->{'cmd_embed-css-partials'},
		'embed-scss-imports!' => \ $config->{'cmd_embed-scss-imports'},
		'embed-scss-partials!' => \ $config->{'cmd_embed-scss-partials'},
		'rebase-urls-in-css!' => \ $config->{'cmd_rebase-urls-in-css'},
		'rebase-urls-in-scss!' => \ $config->{'cmd_rebase-urls-in-scss'}
	);

};
# EO plugin initer

###################################################################################################
###################################################################################################
1;
