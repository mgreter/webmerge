################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Merge;
################################################################################

use strict;
use warnings;

################################################################################

sub execute
{

	# get input arguments
	my ($node, $context) = @_;

	# process all output targets in merge
	foreach my $output ($node->find('OUTPUT'))
	{
		# render the output data
		my $data = $output->render;
		# write the output data to disk
		my $rv = $output->write($data);
		die "could not write data" unless $rv;
	}

}

################################################################################
################################################################################
1;
