################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Output::CSS;
################################################################################
use base qw(
	OCBNET::Webmerge::Output
	OCBNET::Webmerge::IO::File::CSS
);
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::CSS3::Regex::Base qw($re_url);
################################################################################
use OCBNET::CSS3::URI qw(wrapUrl exportUrl fromUrl);
################################################################################

sub export
{

	# get arguments
	my ($output, $data) = @_;

	# call export on parent class
	$output->SUPER::export($data);

	# get new export base dir
	my $base = $output->dirname;

	# alter all urls to paths relative to the base directory
	${$data} =~ s/($re_url)/wrapUrl(exportUrl(fromUrl($1), $base, 0))/ge;

}

################################################################################
################################################################################

sub finalize
{

	# get arguments
	my ($output, $data) = @_;

	# call export on parent class
	$output->SUPER::export($data);

	# get new export base dir
	my $base = $output->webroot;

	# alter all urls to paths relative to the base directory
	${$data} =~ s/($re_url)/wrapUrl(exportUrl(fromUrl($1), $base, 1))/ge;

}

################################################################################
################################################################################
1;