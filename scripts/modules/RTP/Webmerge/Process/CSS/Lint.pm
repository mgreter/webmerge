###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Process::CSS::Lint;
###################################################################################################
# http://support.microsoft.com/kb/262161
#  - A sheet may contain up to 4095 rules
#  - A sheet may @import up to 31 sheets
#  - @import nesting supports up to 4 levels deep
###################################################################################################

use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Process::CSS::Lint::VERSION = "0.9.0" }

###################################################################################################

use Cwd qw(cwd);

###################################################################################################

# process spritesets with additional modules
# try to keep them as standalone as possible
sub csslint
{

	# load the cscc compiler
	require CSS::Sass;

	# get input variables
	my ($data, $config, $output) = @_;

	# load regular expression from spriteset parser
	use OCBNET::CSS::Parser::Base qw(uncomment);
	use OCBNET::CSS::Parser::Selectors qw($re_css_selector_rules);

	my $text = ${$data};

	uncomment($text);

	# count various occurences of items
	# ie does not like to have too many of them
	my @imports = $text =~ /\@import .*?(?:\Z|\n|;)/gm;
	my @selectors = $text =~ /$re_css_selector_rules(?=\s*\{)/gm;

	my $tmpl = "CSSLINT RESULTS: %s selectors and %s imports\n";
	printf $tmpl, scalar(@selectors), scalar(@imports);
	warn "Too many imports in css file for IE\n" if (scalar(@imports) > 30);
	warn "Too many selectors in css file for IE\n" if (scalar(@selectors) > 4000);
	sleep 2 if scalar(@imports) > 30 || scalar(@selectors) > 4000;

	# return success
	return 1;

}
# EO sub scss

###################################################################################################

# import registered processors
use RTP::Webmerge qw(%processors);

# register the processor function
$processors{'csslint'} = \& csslint;

###################################################################################################
###################################################################################################
1;