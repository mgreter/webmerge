###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Include::CSS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Include::CSS::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(includeCSS $css_dev_header); }

###################################################################################################

use RTP::Webmerge::Fingerprint qw(fingerprint);

###################################################################################################

# css header include
#**************************************************************************************************
our $css_dev_header = '';

###################################################################################################

use RTP::Webmerge::Merge qw(collectInputs);

###################################################################################################

# called via array map
#**************************************************************************************************
sub includeCSS
{

	# get passed variables
	my ($block, $config) = @_;

	# magick map variable
	my $input = $_;

	# define the template for the script includes
	# don't care about doctype versions, dev only
	my $css_include_tmpl = '@import url(\'%s\');' . "\n";

	# referenced id
	if ($input->{'id'})
	{

		# collect all inputs for
		my %files;

		# collect references
		my $includes = [];

		# get config from block
		# my $config = $block->{'_config'};

		# create new config scope
		my $scope = $config->stage;

		# re-load the config for this block
		$config->apply($block->{'_conf'})->finalize;

		# call collect merge to collect includes array
		collectInputs($config, $block, 'css', $includes);

		# collect data
		my $data = '';

		# process each include for id
		foreach my $include (@{$includes})
		{

			# get variables from array
			my ($path, $block) = @{$include};

			# get a unique path with added fingerprint (query or directory)
			$path = fingerprint($config, 'dev', $path);

			# return the script include string
			$data .= sprintf($css_include_tmpl, $path);

		}

		# return includes
		return $data;

	}
	# simple input file
	elsif ($input->{'local_path'})
	{


		# get a unique path with added fingerprint (query or directory)
		my $path = fingerprint($config, 'dev', $input->{'local_path'}, $input->{'org'});

		# return the script include string
		return sprintf($css_include_tmpl, $path);

	}
	# input inline data
	elsif ($input->{'data'})
	{

		return ${$input->{'data'}};

	}

}
# EO sub includeCSS

###################################################################################################
###################################################################################################
1;
