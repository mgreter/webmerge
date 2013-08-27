#!/usr/bin/perl

###################################################################################################
package RTP::Webmerge::Optimize;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# global variables
our (%optimizer);

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Optimize::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(optimize); }

# define our functions that can be exported
BEGIN { our @EXPORT_OK = qw(%optimizer fileOptimizer); }

###################################################################################################

# main optimizer function
# call all optimizer steps
sub optimize
{

	# get input variables
	my ($config, $optimize) = @_;

	# check for configuration option
	return unless $config->{'optimize'};

	# do not process if disabled attribute is given and set to true
	unless ($optimize->{'disabled'} && lc $optimize->{'disabled'} eq 'true')
	{

		# change directory (restore previous state after this block)
		my $dir = RTP::Webmerge::Path->chdir($optimize->{'chdir'});

		# process all optimizers
		foreach my $key (sort keys %optimizer)
		{
			# check if this optimizer is enabled
			next unless $config->{'optimize-' . $key};
			# call the optimizer functions (see modules)
			$optimizer{$key}->($config, $optimize->{$key} || []);
		}

	}
	# EO unless disabled

}
# EO sub optimize

###################################################################################################

# load function from main module
use RTP::Webmerge::Path qw(res_path);

# load functions from webmerge io library
use RTP::Webmerge::IO qw(filelist);

# load function from main module
use RTP::Webmerge qw(callProgram);

###################################################################################################

# create a new sub to optimize files
# pass the filetype to be optimized
sub fileOptimizer ($)
{

	# create a closure variable
	my ($filetype) = @_;

	# create new subroutine
	return sub
	{

		# get input variables
		my ($config, $entries) = @_;

		# process all entries
		foreach my $nodes (@{$entries})
		{

			# declare lexical variables
			my $disabled = $nodes->{'disabled'};

			# do not process if entry has been disabled
			return if $disabled && lc $disabled eq 'true';

			# process all file entries
			foreach my $entry (@{$nodes->{'file'} || []})
			{

				# declare lexical variables
				my $file = $entry->{'file'};
				my $path = $entry->{'path'} || '.';
				my $disabled = $entry->{'disabled'};
				my $recursive = $entry->{'recursive'};

				# do not process if entry has been disabled
				return if $disabled && lc $disabled eq 'true';

				# create pattern for logging
				my $pattern = join('/', $path, $file);

				# get all files for the resolved path and pattern
				my $files = filelist(res_path($path), $file, $recursive);

				# call all possible optimizers
				callProgram($config, $filetype . 'opt', $files, $pattern);

			}
			# EO each file entry

		}
		# EO each nodes

	};
	# EO sub optimizer

}
# EO sub fileOptimizer

###################################################################################################
###################################################################################################
1;