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
BEGIN { $RTP::Webmerge::Path::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our variables to be exported
BEGIN { our @EXPORT = qw(dirname res_path check_path exportURI importURI); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw(EOD basename $webroot $confroot $extroot $directory); }

###################################################################################################

# use cwd to normalize paths
use Cwd qw(realpath abs_path);

# use to parse path and filename
use File::Basename qw(dirname basename);

# import system path conversion functions
use File::Spec::Functions qw(rel2abs abs2rel);

###################################################################################################

# directory delimiter for supported OS
sub EOD { $^O eq "MSWin32" ? '\\' : '/'; }

###################################################################################################

# resolve URI to an absolute path on filesystem
# directory has to exist, but not the actual file
sub importURI
{

	# get URI and local path
	my ($uri, $relpath) = @_;

	# set relpath to webroot if nothin else given
	$relpath = $webroot unless defined $relpath;

	# remove hash tag and query string for URI
	my $suffix = $uri =~ s/([\;\?\#].*?)$// ? $1 : '';

	# get path and filename
	my $path = dirname $uri;
	my $file = basename $uri;

	# check if URI is absolute
	if ($uri =~ m/^\//)
	{
		# absolute uris should be loaded from webroot
		# if you need another webroot, localize it before
		$path = realpath(join('/', $webroot, $path));
	}
	else
	{
		# relative uris load from parent cssfile
		$path = realpath(rel2abs($path, $relpath));
	}

	# assert that at least the path of the URI exists on the actual filesystem
	die "URI($uri) could not be imported (CWD: $relpath)\n" unless $path && -d $path;

	# return the final absolute local path
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
	my ($path, $relpath, $abs) = @_;

	# set relpath to webroot if nothin else given
	$relpath = $webroot unless defined $relpath;

	# relative URI from relpath
	my $uri = abs2rel($path, $relpath);

	# normalize directory delimiters on win
	$uri =~ s/\\+/\//g if $^O eq "MSWin32";

	# create absolute URI if set
	$uri = '/' . $uri if $abs;

	# return URI
	return $uri;

}
# EO sub exportURI

###################################################################################################

# resolve path with special markers for directories
# will replace {EXT}, {WWW} and {CONF} is given paths
# also make relative paths relative to current directory
sub res_path ($)
{

	# get path string
	my ($path) = @_;

	# make some assertions and give die message from parent
	Carp::croak "check_path with undefined path called" if not defined $path;
	Carp::croak "check_path with empty path called" if $path eq '';

	# replace variables within path
	# make dollar sign mandatory in future
	$path =~ s/\$?\{EXT\}/$extroot/gm if $extroot;
	$path =~ s/\$?\{WWW\}/$webroot/gm if $webroot;
	$path =~ s/\$?\{CONF\}/$confroot/gm if $confroot;

	# return if path is already absolute
	return $path if $path =~m /^(?:\/|[a-zA-Z]:)/;

	# prepended current directory and return
	return join('/', $directory || '.', $path);

}

###################################################################################################

# same as resolve path but check for existence of the parent directory
# will resolve path to current filesystem and returns an absolute path
sub check_path ($)
{

	# resolve the path string
	my $path = &res_path;

	# create absolute path for the directory and re-add filename
	# abs_path will error out if the given path does not exist
	return join('/', abs_path(dirname($path)), basename($path));

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

	# check that we have some arguments (test attribute)
	return unless defined $chdirs && $chdirs ne '';
	# make sure that we have an array in the end
	# we also support strings as input -> normalize
	$chdirs = [$chdirs] if ref $chdirs ne 'ARRAY';
	# check that we have some input arguments
	return if scalar(@{$chdirs}) == 0;

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
