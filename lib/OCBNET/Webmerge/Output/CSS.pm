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

sub importURL ($;$) { OCBNET::CSS3::URI->new($_[0], $_[1])->wrap }
sub exportURL ($;$) { OCBNET::CSS3::URI->new($_[0])->export($_[1]) }

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
	${$data} =~ s/($re_url)/OCBNET::CSS3::URI->new($1)->export($base)/ge;
}

################################################################################
################################################################################
1;