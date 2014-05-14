################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File::CSS::Export;
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::CSS3::Regex::Base qw($re_url);
################################################################################
use OCBNET::CSS3::URI qw(exportWrapUrl);
################################################################################

sub exporter
{

	# get arguments
	my ($output, $data) = @_;

	# call export on parent class
	# $output->SUPER::exporter($data);

	# check if we export urls as absolute paths
	my $abs = $output->option('absoluteurls');

	# get new export base dir according to options
	my $base = $abs ? $output->webroot : $output->baseroot;

	# alter all urls to paths relative to the base directory
	${$data} =~ s/($re_url)/exportWrapUrl($1, $base, $abs)/ge;

}

################################################################################
################################################################################
1;
