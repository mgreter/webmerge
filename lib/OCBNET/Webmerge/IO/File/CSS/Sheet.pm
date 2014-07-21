################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File::CSS::Sheet;
################################################################################

use strict;
use warnings;

################################################################################
# return parsed stylesheet
################################################################################
use OCBNET::CSS3;
################################################################################

sub sheet
{

	# get arguments
	my ($file, $data) = @_;
	# check if we have it cached
	if (exists $file->{'sheet'})
	{ return $file->{'sheet'}; }
	# create a new stylesheet
	my $sheet = OCBNET::CSS3->new;
	# parse the passed data or read from file
	$sheet->parse(${$data || $file->contents});
	# store to cache and return sheet
	return $file->{'sheet'} = $sheet;

}

################################################################################
################################################################################
1;
