################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Output::CSS;
################################################################################
use base 'OCBNET::Webmerge::Output';
################################################################################

use strict;
use warnings;

################################################################################

sub compile
{

	# get input variables
	my ($output, $content) = @_;

	# module is optional
	require CSS::Minifier;

	# minify via the perl cpan minifyer
	compileCSS($content, { 'level' => 1, 'pretty' => 0 });

}

sub minify
{

	# get input variables
	my ($output, $content) = @_;

	# module is optional
	require CSS::Minifier;

	# minify via the perl cpan minifyer
	CSS::Minifier::minify('input' => $content);

}

################################################################################
use OCBNET::CSS3::Minify;
################################################################################

################################################################################
################################################################################
1;