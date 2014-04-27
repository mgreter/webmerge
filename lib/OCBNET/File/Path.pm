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
BEGIN { push @EXPORT, qw(mkdir mkpath) }

################################################################################
use Errno qw(EROFS);
################################################################################
# create a single directory (chrooted)
################################################################################
use File::Spec::Functions qw(canonpath rel2abs);
################################################################################

sub mkdir
{

	# get input arguments
	my ($path, %option) = @_;

	# get chroot from options
	my $chroot = $option{'chroot'};

	# make absolute path of mkdir directory
	$path = rel2abs $path if defined $path;
	# make absolute path of chroot directory
	$chroot = rel2abs $chroot if defined $chroot;

	# check if the path lies outside the chroot
	if ($chroot && index($path, $chroot) != 0)
	{
		warn "WARN: mkdir outside of chroot\n";
		warn "WARN:    path: $path\n";
		warn "WARN:  chroot: $chroot\n";
		$! = EROFS; ();
	}
	else
	{
		mkdir $path;
	}

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
		# create directory if not yet existing
		&mkdir($path, %option) unless -d $path;
	}

}

################################################################################
################################################################################
1;
