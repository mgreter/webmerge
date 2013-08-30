#!/usr/bin/perl

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
BEGIN { our @EXPORT_OK = qw($webroot $confroot $extroot $directory); }

# define our variables to be exported
BEGIN { our @EXPORT = qw(resolve_path res_path fast_res_path web_url web_path); }

###################################################################################################

# use cwd to normalize paths
use Cwd qw(abs_path fast_abs_path);

# use to parse path and filename
use File::Basename qw(dirname basename);

###################################################################################################

# return url for web from path
sub web_url ($)
{

	# get path string
	my ($path) = @_;

	# resolve path to absolute
	$path = join("/", abs_path(dirname($path)), basename($path));

	# resolve the webroot absolute
	my $root = abs_path($webroot);

	# remove docroot directory
	# should leave an absolute url
	# relative to the given webroot
	$path =~ s/^\Q$root\E//;

	# return web url
	return $path;

}
# EO sub web_path

###################################################################################################

# return path from url for web
sub web_path ($)
{

	# get path string
	my ($abs_webpath) = @_;

	# return web path
	return join('/', $webroot, $abs_webpath);

}

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

	# prepended current directory and return
	return join('/', $directory || '.', $path);

}

###################################################################################################

# pass through abs_path function
sub res_path ($)
{

	# resolve the path string
	my $path = &resolve_path;

	# create absolute path for the directory and re-add filename
	return join('/', abs_path(dirname($path)), basename($path));

}

# pass through fast_abs_path function
sub fast_res_path ($)
{

	# resolve the path string
	my $path = &resolve_path;

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
	$directory = '.' unless $directory;

	# assertion that we have some valid arguments
	return unless $chdirs && scalar(@{$chdirs}) > 0;

	# create a new variable
	my $dir = $directory;

	# accept array as chdirs argument
	foreach my $chdir (@{$chdirs || []})
	{
		# now change our current directory variable
		if ($chdir =~ m/^(?:\/|[a-zA-Z]:)/) { $directory = $chdir; }
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
