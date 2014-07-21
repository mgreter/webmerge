################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::File::Path;
################################################################################

use strict;
use warnings;

################################################################################

# declare for exporter
our (@EXPORT, @EXPORT_OK);

# load exporter and inherit from it
BEGIN { use base 'Exporter'; }

# define our functions that will be exported
BEGIN { push @EXPORT, qw(mkdir mkpath safechroot) }

################################################################################
use Errno qw(EROFS ENOENT);
################################################################################
# create a single directory (chrooted)
################################################################################
use File::Spec::Functions qw(canonpath rel2abs);
################################################################################

sub safechroot
{

	# get input arguments
	my ($path, $chroot) = @_;

	# make absolute path of mkdir directory
	$path = rel2abs $path if defined $path;
	# return immediately if path not found
	return $path unless defined $path;
	# make absolute path of chroot directory
	$chroot = rel2abs $chroot if defined $chroot;
	# return immediately if no chroot given
	return $path unless defined $chroot;

	# check if the path is outside chroot
	if (index($path, $chroot) != 0)
	{
		warn "WARN: mkdir outside of chroot\n";
		warn "WARN:    path: $path\n";
		warn "WARN:  chroot: $chroot\n";
		$! = EROFS; return ();
	}

}
# EO chrootsafe

################################################################################
# create directory (check for chroot base)
################################################################################

sub mkdir
{

	# get input arguments
	my ($path, %option) = @_;

	# get chroot from options
	my $chroot = $option{'chroot'};

	# make absolute path of directory
	$path = safechroot $path, $chroot;

	# assertion if the path could not be resolved
	die "error resolving path: $!" unless $path;

	# create directory
	return mkdir $path;

}

################################################################################
# create a path with all subdirectories
################################################################################
use File::Spec::Functions qw(splitdir catdir);
################################################################################

sub mkpath
{

	# get input arguments
	my ($mkpath, %option) = @_;

	# split path into directory parts
	my @path = splitdir(canonpath($mkpath));
	# filter out various unwanted path parts
	@path = grep { ! $_ =~ m/\A\.{0,2}\z/ } @path;

	# process directories from the left
	for (my $i = 0; $i < scalar(@path); $i++)
	{
		# create path from path parts
		my $path = catdir(@path[0 .. $i]);
		# skip if it exists
		next if -d $path;
		# fail if not directory
		return 0 if -e $path;
		# create directory (abort on error)
		&mkdir($path, %option) || return 0;
	}

	# success
	return 1;

}

################################################################################
################################################################################
1;
