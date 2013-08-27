#!/usr/bin/perl

###################################################################################################
package RTP::Webmerge::IO::CSS;
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
BEGIN { $RTP::Webmerge::IO::CSS::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our variables to be exported
BEGIN { our @EXPORT = qw(importCSS exportCSS); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw($re_url wrapURL); }

###################################################################################################

# load perl core file functions
use File::Basename qw(dirname basename);
use File::Spec::Functions qw(rel2abs abs2rel canonpath);

# load webmerge file reader
use RTP::Webmerge::IO qw(readfile writefile);

use RTP::Webmerge::Path qw($webroot);

use RTP::Webmerge::Path qw(web_url);

use Cwd qw(realpath);

###################################################################################################

# wrap url for css
# also makes it canonical
sub wrapURL
{

	# get uri
	my ($uri) = @_;

	# escape apostrophes
	$uri =~ s/\'/\\\'/g;

	# replace windows backslashed
	# with correct forward slashes
	$uri =~ s/\\/\//g if ($^O eq "MSWin32");

	# wrap and return escaped uri
	return sprintf("url('%s')", $uri);

}
# EO wrapURL

###################################################################################################

# check if url is available
# and make the path absolute
sub importURI
{

	# get the url and css path
	my ($url, $cssfile) = @_;

	# check if the url is actually
	return wrapURL($url) if ($url =~ m/^(?:[a-zA-Z]+\:)?\/\//);

	# remove hash tag and query string
	# why is this needed for a static file?
	my $append = $url =~ s/([\?\#].*?)$// ? $1 : '';

	# create the path relative first
	# my $path = join('', dirname($cssfile), $url);

	# create absolute path from the url if exists
	my $path = realpath(rel2abs(dirname($url), dirname($cssfile)));

	# check path on filesystem and
	die "CSS url($url) in <$cssfile> not found\n" unless ($path && -e $path);

	# now re attach the file name for the resource
	$path = join('/', $path, basename($url));

	# return the wrapped url
	return wrapURL($path . $append);

}
# EO importURI

###################################################################################################

# export url and make it relative
sub exportURI
{

	# get input variables
	my ($url, $cssfile, $config) = @_;

	# get absolute or relative path
	my $path = $config->{'absoluteurls'}
	           ? '/' . abs2rel($url, $webroot)
	           : abs2rel($url, dirname($cssfile));

	# return the wrapped url
	return wrapURL($path);

}
# EO exportURI

###################################################################################################


# read a css file from the disk
# resolve all file paths absolute
# http://www.w3.org/TR/CSS21/syndata.html#uri
sub importCSS
{

	# get input variables
	my ($cssfile) = @_;

	# read complete css file
	my $data = readfile($cssfile);

	# die with an error message that css file is not found
	die "css import <$cssfile> could not be read: $!\n" unless $data;

	# change all relative urls in this css to absolute paths
	# also look for comments, but do not change them in the function
	${$data} =~ s/$re_url/importURI($1, $cssfile)/egm;

	# resolve all css imports and include in data
	${$data} =~ s/\@import\s+$re_url/${importCSS($1)}/gme;

	# return as string
	return $data;

}
# EO importCSS

###################################################################################################

# write a css file to the disk
# resolve all file paths relative
# http://www.w3.org/TR/CSS21/syndata.html#uri
sub exportCSS
{

	# get input variables
	my ($path, $data, $config) = @_;

	# change all absolute urls in this css to relative paths
	# also look for comments, but do not change them in the function
	${$data} =~ s/(?:(\/\*.*?\*\/)|$re_url)/$1 || exportURI($2, $path, $config)/egm;

	# call io function to write the file atomically
	return writefile($path, $data, $config->{'atomic'})

}
# EO exportCSS

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
	# for this option we need to webroot path
	$config->{'absoluteurls'} = 0;

	# return additional get options attribute
	return ('absoluteurls=i' => \ $config->{'cmd_absoluteurls'});

};
# EO plugin initer

###################################################################################################
###################################################################################################
1;
