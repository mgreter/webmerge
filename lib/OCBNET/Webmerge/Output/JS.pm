################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Output::JS;
################################################################################
use base qw(
	OCBNET::Webmerge::Output
	OCBNET::Webmerge::IO::File::JS
);
################################################################################

use strict;
use warnings;

################################################################################

# js function for header include
# you can overwrite and control all bits by defining your own
# javascript functions before including the generated dev file
#**************************************************************************************************
our $js_dev_header = <<JSHEAD;

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

JSHEAD

################################################################################
# custom preserved prefix for output
################################################################################

sub prefix
{

	# get arguments
	my ($output) = @_;

	# only continue if in dev mode
	return if $output->target ne "dev";

	# return dev prefix
	return $js_dev_header;

}

################################################################################
# custom preserved suffix for output
################################################################################

sub suffix
{

	# get arguments
	my ($output) = @_;

	# only continue if in dev mode
	return if $output->target ne "dev";

	# return dev suffix
	return "/* suffix */";

}

################################################################################
################################################################################
1;
















__DATA__



###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Compile::JS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Compile::JS::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(compileJS); }

###################################################################################################


# run3 to get stdout and stderr
use RTP::Webmerge::Path qw(EOD $extroot check_path);

###################################################################################################

###################################################################################################
###################################################################################################
1;
