###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Path;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# global variables for various paths
# $webroot: absolute path to htdocs root
# $confroot: directory of the config file
# $directory: our current working directory
our ($webroot, $confroot, $extroot, $directory);

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Path::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw(EOD $webroot $confroot $extroot $directory exportURI importURI); }

# define our variables to be exported
BEGIN { our @EXPORT = qw(resolve_path res_path fast_res_path web_url web_path); }

###################################################################################################

# use to parse path and filename
use File::Basename qw(dirname basename);

# import system path conversion functions
use File::Spec::Functions qw(rel2abs abs2rel);

# use cwd to normalize paths
use Cwd qw(realpath abs_path fast_abs_path);

###################################################################################################

# directory delimiter
sub EOD
{
	$^O eq "MSWin32" ? '\\' : '/';
}

# return url for web from path
sub web_url ($)
{
	return '/' . exportURI($_[0], $webroot, 1)
}
# EO sub web_path

###################################################################################################

# resolve URI to an absolute path on filesystem
# directory has to exist, but not the actual file
sub importURI
{

	# get uri and local path
	my ($uri, $localpath) = @_;

	# set localpath to webroot if nothin else given
	$localpath = $webroot unless defined $localpath;

	# remove hash tag and query string for uri
	my $suffix = $uri =~ s/([\;\?\#].*?)$// ? $1 : '';

	# get path and filename
	my $path = dirname $uri;
	my $file = basename $uri;

	# check if uri is absolute
	if ($uri =~ m/^\//)
	{
		# absolute uris should be loaded from webroot
		# if you need another webroot, localize it before
		$path = realpath(join('/', $webroot, $path));
	}
	else
	{
		# relative uris load from parent cssfile
		$path = realpath(rel2abs($path, $localpath));
	}

	# assert that at least the path of the uri exists on the actual filesystem
	die "URI($uri) could not be imported (CWD: $localpath)\n" unless $path && -d $path;

	# return the final absolute local url
	# the suffix is lost as we convert the
	# URI to a real absolute local filepath
	return join('/', $path, $file);

}
# EO sub importURI

###################################################################################################

# export an absolute path on filesystem to an URI
# maybe absolute or relative from the given path
# if no path is given, we use the global webroot
sub exportURI ($;$$)
{

	# get input variables
	my ($url, $localpath, $abs) = @_;

	# set localpath to webroot if nothin else given
	$localpath = $webroot unless defined $localpath;

	# relative url from localpath
	$url = abs2rel($url, $localpath);

	# normalize directory delimiters on win
	$url =~ s/\\+/\//g if $^O eq "MSWin32";

	# create absolute url if set
	$url = '/' . $url if $abs;

	# return url
	return $url;

}
# EO sub exportURI

###################################################################################################

# resolve path
sub resolve_path ($)
{

	# get path string
	my ($path) = @_;

	# make some assertions
	Carp::croak "res_path with undefined path called" if not defined $path;
	Carp::croak "res_path with empty path called" if $path eq '';

	# replace some variables
	$path =~ s/\{EXT\}/$extroot/gm if $extroot;
	$path =~ s/\{WWW\}/$webroot/gm if $webroot;
	$path =~ s/\{CONF\}/$confroot/gm if $confroot;

	# return if path is already absolute
	return $path if $path =~m /^(?:\/|[a-zA-Z]:)/;

	$path =~ s/[\/\\]+/\//g;

	# prepended current directory and return
	return join('/', $directory || '.', $path);

}

###################################################################################################

# pass through abs_path function
sub res_path ($)
{

	# resolve the path string
	my $path = &resolve_path;
	$path =~ s/[\/\\]+/\//g;
	# create absolute path for the directory and re-add filename
	return join('/', abs_path(dirname($path)), basename($path));

}

# pass through fast_abs_path function
sub fast_res_path ($)
{

	# resolve the path string
	my $path = &resolve_path;
	$path =~ s/[\/\\]+/\//g;

	# create absolute path for the directory and re-add filename
	return join('/', fast_abs_path(dirname($path)), basename($path));

}

###################################################################################################

# change current directory
# returns an object you have to hold on
# as soon as the object is destroyed we
# restore the previous current directory
sub chdir
{

	# chdir arguments
	my ($self, $chdirs) = @_;

	# assert that current has some value
	$directory = abs_path '.' unless $directory;

	# assertion that we have some valid arguments
	return unless $chdirs && scalar(@{$chdirs}) > 0;

	# create a new variable
	my $dir = $directory;

	# accept array as chdirs argument
	foreach my $chdir (@{$chdirs || []})
	{
		# now change our current directory variable
		if ($chdir =~ m/^(?:\/|[a-z]:)/i) { $directory = $chdir; }
		else { $directory = join('/', $directory, $chdir); }
	}

	# give a message to the console for debug
	# print "changed directory => $directory\n";

	# assertion that the directory does actually exist
	die "chdir failed, directory <$directory> does not exist!\n" unless -d $directory;

	# resolve to an absolute path
	$directory = abs_path($directory);

	# bless scalar reference
	return bless \ $dir, $self;

}


###################################################################################################

# restore the saved directory
sub DESTROY
{

	# destroy arguments
	my ($self) = @_;

	# restore old directory
	$directory = ${$self};

	# give a message to the console for debug
	# print "restored directory => $directory\n";

}


###################################################################################################
###################################################################################################
1;
