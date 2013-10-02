###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Merge::Include;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Merge::Include::VERSION = "0.7.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(includeJS includeCSS $js_dev_header $css_dev_header); }

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

# css header include
#**************************************************************************************************
our $css_dev_header = '';

###################################################################################################

# called via array map
#**************************************************************************************************
sub includeJS
{

	# get passed variables
	my ($config) = @_;

	# magick map variable
	my $data = $_;

	# define the template for the script includes
	my $js_include_tmpl = 'webmerge.includeJS(\'%s\');' . "\n";

	# get a unique path with added fingerprint (query or directory)
	my $path = fingerprint($config, 'dev', $data->{'local_path'}, $data->{'org'});

	# return the script include string
	return sprintf($js_include_tmpl, exportURI($path, $webroot, 1));

}
# EO includeJS

###################################################################################################

# called via array map
#**************************************************************************************************
sub includeCSS
{

	# get passed variables
	my ($config) = @_;

	# magick map variable
	my $data = $_;

	# define the template for the script includes (don't care about doctype versions, dev only)
	my $css_include_tmpl = '@import url(\'%s\');' . "\n";

	# get a unique path with added fingerprint (query or directory)
	my $path = fingerprint($config, 'dev', $data->{'local_path'}, $data->{'org'});

	# return the script include string
	return sprintf($css_include_tmpl, $path);

}
# EO sub includeCSS

###################################################################################################
###################################################################################################
1;
