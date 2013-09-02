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
BEGIN { $RTP::Webmerge::IO::CSS::VERSION = "0.8.2" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our variables to be exported
BEGIN { our @EXPORT = qw(incCSS readCSS importCSS exportCSS writeCSS); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw($re_url wrapURL exportURL importURI); }

###################################################################################################

# import path resolver
use Cwd qw(realpath);

# import core file functions
use File::Basename qw(dirname basename);

# import system path conversion functions
use File::Spec::Functions qw(rel2abs abs2rel);

# import webmerge io file reader and writer
use RTP::Webmerge::IO qw(readfile writefile);

# import local webroot path
use RTP::Webmerge::Path qw($webroot);

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

# resolve css url to absolute path on filesystem
# directory has to exist, but not the actual file
sub importURI
{

	# get the uri and css path
	my ($uri, $csspath, $config) = @_;

	# remove hash tag and query string for uri
	my $suffix = $uri =~ s/([\?\#].*?)$// ? $1 : '';

	# get path and filename
	my $path = dirname $uri;
	my $file = basename $uri;

	# check if uri is absolute
	if ($uri =~ m/^\//)
	{
		# absolute uris should be loaded from webroot
		$path = realpath(join('/', $webroot, $path));
	}
	else
	{
		# relative uris load from parent cssfile
		$path = realpath(rel2abs($path, $csspath));
	}

	# assert that the path of the uri exists on the actual filesystem
	die "CSS uri($uri) not found (css path: $csspath)\n" unless $path && -d $path;

	# return the final absolute local url
	return join('/', $path, basename($uri));

}
# EO sub importURI

###################################################################################################

# export filesystem url to web uri
sub exportURL
{

	# get input variables
	my ($url, $csspath, $config) = @_;

	# check if we export absolute uris
	if ($config->{'absoluteurls'})
	{
		# absolute url from webroot
		$url = '/' . abs2rel($url, $webroot);
	}
	else
	{
		# relative url from csspath
		$url = abs2rel($url, $csspath);
	}

	# normalize directory delimiters on win
	$url =~ s/\\+/\//g if $^O eq "MSWin32";

	# return url
	return $url;

}
# EO sub exportURL

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
	${$data} =~ s/$re_url/wrapURL(exportURL($1, $webroot, $config))/egm;

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
	${$data} =~ s/$re_url/wrapURL(importURI($1, $webroot, $config))/egm;

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
	${$data} =~ s/$re_url/wrapURL(exportURL($1, dirname($file), $config))/egm;

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
		'absoluteurls=i' => \ $config->{'cmd_absoluteurls'}
	);

};
# EO plugin initer

###################################################################################################
###################################################################################################
1;
