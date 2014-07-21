################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::Read;
################################################################################

use strict;
use warnings;

################################################################################
# read and import file
################################################################################

sub read
{

	# get arguments
	my $file = shift;

	# load from disk
	my $data = $file->load(@_);

	# import relative urls
	$file->importer($data);

	# resolve all imports
	$file->resolve($data);

	# call the processors
	$file->process($data);

	# return reference
	return $data;

}

################################################################################
################################################################################
1;

