################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::File::Output::JS;
################################################################################
use base qw(OCBNET::Webmerge::IO::Mixin::Checksum);
use base qw(OCBNET::Webmerge::IO::Mixin::SourceMap);
################################################################################
# this might change again?
# needed so the processor is run!
################################################################################
use base qw(OCBNET::Webmerge::File::Output);
use base qw(OCBNET::Webmerge::IO::File::JS);
################################################################################

# define the header text for js dev includes
#*******************************************************************************
my $js_header = <<HEADER;
// *****************************************************************************
// define some standard functions to include the js files
// you can define your own functions to adjust paths etc.
// *****************************************************************************

// create namespace for webmerge if not yet defined
if (typeof webmerge == 'undefined') window.webmerge = {};

// define default JS loader function, overwrite with
// other defered JS loaders like head.hs or requireJS
if (typeof webmerge.loadJS != 'function')
{
	webmerge.loadJS = function (src)
	{
		document.write('<script src="' + src + '"></script>');
	}
}

// include a JS file (rewrite url if configured to)
// then call the loadJS function to import the code
if (typeof webmerge.includeJS != 'function')
{
	webmerge.includeJS = function (src)
	{
		// check if we have a custom webroot
		if (webmerge.webroot) src = [webmerge.webroot, src].join('/');
		// check if we have a custom url rewriter
		if (webmerge.rewriteJS) src = webmerge.rewriteJS(src);
		// call the importer function, which
		// can be overwritten by a custom loader
		webmerge.loadJS.call(this, src);
	}
}

// *****************************************************************************

HEADER

################################################################################

# define the footer text for js dev includes
#*******************************************************************************
my $js_footer = <<FOOTER;

// *****************************************************************************
/* end of webmerge dev includes */
// *****************************************************************************
FOOTER

################################################################################
################################################################################

sub prefix { $js_header }
sub suffix { $js_footer }

################################################################################
################################################################################
1;
