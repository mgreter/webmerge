###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Include::JS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Include::JS::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(includeJS $js_dev_header); }

###################################################################################################

use RTP::Webmerge::Path qw($webroot exportURI);
use RTP::Webmerge::Fingerprint qw(fingerprint);

###################################################################################################

# js function for header include
# you can overwrite and control all bits by defining your own
# javascript functions before including the generated dev file
#**************************************************************************************************
our $js_dev_header =
'
// create namespace for webmerge if not yet defined
if (typeof webmerge == \'undefined\') window.webmerge = {};

// define default JS loader function, overwrite with
// other defered JS loaders like head.hs or requireJS
if (typeof webmerge.loadJS != \'function\')
{
	webmerge.loadJS = function (src)
	{
		document.write(\'<script src="\' + src + \'"></script>\');
	}
}

// include a JS file (rewrite url if configured to)
// then call the loadJS function to import the code
if (typeof webmerge.includeJS != \'function\')
{
	webmerge.includeJS = function (src)
	{
		// check if we have a custom webroot
		if (webmerge.webroot) src = [webmerge.webroot, src].join(\'/\');
		// check if we have a custom url rewriter
		if (webmerge.rewriteJS) src = webmerge.rewriteJS(src);
		// call the importer function, which
		// can be overwritten by a custom loader
		webmerge.loadJS.call(this, src);
	}
}

';

###################################################################################################

use RTP::Webmerge::Merge qw(collectInputs);

###################################################################################################

# called via array map
#**************************************************************************************************
sub includeJS
{

	# get passed variables
	my ($block) = @_;

	# magick map variable
	my $input = $_;

	# define the template for the script includes
	my $js_include_tmpl = 'webmerge.includeJS(\'%s\');' . "\n";

	# referenced id
	if ($input->{'id'})
	{

		# collect all inputs for
		my %files;

		# collect references
		my $includes = [];

		# get config from block
		my $config = $block->{'_config'};

		# create new config scope
		my $scope = $config->stage;

		# re-load the config for this block
		$config->apply($block->{'_conf'})->finalize;

		# call collect merge to collect includes array
		collectInputs($config, $block, 'js', $includes);

		# call deconstructor
		undef $scope;

		# collect data
		my $data = '';

		# process each include for id
		foreach my $include (@{$includes})
		{

			# get variables from array
			my ($path, $block) = @{$include};

			# get a unique path with added fingerprint (query or directory)
			$path = fingerprint($block, 'dev', $path);

			# return the script include string
			$data .= sprintf($js_include_tmpl, exportURI($path, $webroot, 1));

		}

		# return includes
		return $data;

	}
	# simple input
	else
	{

		# get a unique path with added fingerprint (query or directory)
		my $path = fingerprint($block, 'dev', $input->{'local_path'}, $input->{'org'});

		# return the script include string
		return sprintf($js_include_tmpl, exportURI($path, $webroot, 1));

	}

}
# EO includeJS

###################################################################################################
###################################################################################################
1;
