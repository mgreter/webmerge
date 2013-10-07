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
