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
require File::Find;
################################################################################
use Text::Glob qw(glob_to_regex_string);
use File::Spec::Functions qw(canonpath);
use File::Spec::Functions qw(abs2rel rel2abs);
################################################################################

sub find
{

	# get input arguments
	my ($pattern, %option) = @_;

	# force forward slashes (windows only)
	$pattern =~ tr/\\/\// if $^O eq 'MSWin32';

	# setup options for regex compilation
	local $Text::Glob::strict_leading_dot = 0;
	local $Text::Glob::strict_wildcard_slash = 0;

	# convert the glob pattern to a regex
	$pattern = glob_to_regex_string($pattern);
	# compile the pattern to a regex
	my $re_pattern = qr/$pattern\Z/;

	# get callback from options
	my $cb = $option{'cb'};
	# format the file paths relative
	my $rel = $option{'rel'} || 0;
	# get base directory from options
	my $base = $option{'base'} || '.';
	# get the filter function to filter results
	my $filter = $option{'filter'} || 0;
	# get maximum directory depth from options
	my $maxdepth = $option{'maxdepth'} || -1;

	# make canonical path
	$base = canonpath($base);

	# declare and init variables
	my ($lvl, @results) = (0);

	# run main find
	File::Find::find({

		# not needed
		no_chdir => 1,

		# increase levels
		preprocess => sub
		{
			$lvl ++;
			@_;
		},

		# decrease levels
		postprocess => sub
		{
			$lvl --;
			@_;
		},

		# main function
		# see File::Find
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
			# map to absolute path to working directory
			elsif ($rel < 1) { $path = rel2abs $path; }

			# make canonical path
			$path = canonpath($path);

			# force forward slashes (windows only)
			$path =~ tr/\\/\// if $^O eq 'MSWin32';

			# check if file matches the pattern
			return unless $path =~ m/$re_pattern/;

			# call back the caller
			$cb->($path) if ($cb);
			# push item to result
			push @results, $path;

		}
	}, $base);

	# return unfiltered results
	unless ($filter) { @results }
	# reduce results if a filter is passed
	# must be a function suitable for grep
	else { grep &{$filter}, @results }

}

################################################################################
################################################################################
1;
