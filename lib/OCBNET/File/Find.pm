################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::File::Find;
################################################################################

use strict;
use warnings;

################################################################################

# declare for exporter
our (@EXPORT, @EXPORT_OK);

# load exporter and inherit from it
BEGIN { use base 'Exporter'; }

# define our functions that will be exported
BEGIN { push @EXPORT, qw(find) }

################################################################################
use Text::Glob qw(glob_to_regex_string);
use File::Spec::Functions qw(canonpath);
use File::Spec::Functions qw(abs2rel rel2abs);
################################################################################
require File::Find;
################################################################################

sub find
{

	# get input arguments
	my ($pattern, %option) = @_;
	# force forward slashes
	$pattern =~ tr/\\/\//;
	# setup options for regex compilation
	local $Text::Glob::strict_leading_dot = 0;
	local $Text::Glob::strict_wildcard_slash = 0;
	# convert the glob pattern to a regex
	$pattern = glob_to_regex_string($pattern);
	# compile the pattern to a regex
	my $re_pattern = qr/$pattern\Z/;
	# get maximum directory depth from options
	my $maxdepth = $option{'maxdepth'} || -1;
	# get base directory from options
	my $base = $option{'base'} || '.';
	# format the file paths relative
	my $rel = $option{'rel'} || 0;
	# get callback from options
	my $cb = $option{'cb'};

	# make canonical path
	$base = canonpath($base);

	# declare and init variables
	my ($lvl, @results) = (0);

	# run finder
	File::Find::find({

		no_chdir => 1,

		preprocess => sub
		{
			$lvl ++;
			@_;
		},

		postprocess => sub
		{
			$lvl --;
			@_;
		},

		wanted => sub
		{

			# set conditionally
			# is localized already
			if (defined $maxdepth)
			{
				$File::Find::prune = 1 if $lvl > $maxdepth;
				$File::Find::prune = 0 if $maxdepth < 0;
			}

			# get the full filename
			my $path = $File::Find::name;
			my $topdir = $File::Find::topdir;
			my $topdev = $File::Find::topdev;
			my $topino = $File::Find::topino;
			my $topmode = $File::Find::topmode;
			my $topnlink = $File::Find::topnlink;

			# map to relative path from base directory
			if ($rel > 1) { $path = abs2rel $path, $base; }
			elsif ($rel < 1) { $path = rel2abs $path; }

			# make canonical path
			$path = canonpath($path);
			# force forward slashes
			# only needed on windows
			$path =~ tr/\\/\//;

			# check if file matches the pattern
			return unless $path =~ m/$re_pattern/;

			# call back the caller
			$cb->($path) if ($cb);
			# push item to result
			push @results, $path;

		}
	}, $base);

	# return
	@results;

}

################################################################################
################################################################################
1;
