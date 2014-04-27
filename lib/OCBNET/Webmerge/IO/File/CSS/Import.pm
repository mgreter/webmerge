################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File::CSS::Import;
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::CSS3::Regex::Base qw($re_url);
################################################################################
use OCBNET::CSS3::URI qw(importWrapUrl);
################################################################################

use File::Basename qw();


sub importer
{

	# get arguments
	my ($input, $data) = @_;

	# call export on parent class
	# $output->SUPER::importer($data);

	# get import base and root
	my $root = $input->webroot;
	my $base = $input->baseroot;

	# alter all urls to absolute paths (relative to base directory)
	${$data} =~ s/($re_url)/importWrapUrl($1, $base, $root)/ge;

}

################################################################################
################################################################################
1;
