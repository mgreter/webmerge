################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Tool::Checksum;
################################################################################

use strict;
use warnings;

################################################################################
use List::MoreUtils qw(uniq);
################################################################################

sub checksum
{

	# get arguments
	foreach my $block (uniq @_)
	{

		# process all output nodes for crc check
		foreach my $output ($block->collect('OUTPUT'))
		{
			# write out changes
			$block->commit(1);

			# create path to store checksum of this output
			my $checksum = OCBNET::Webmerge::CRC->new($output);

			# do a check against the crc content
			my $crc = $output->check($checksum->read);

			# die $crc;
		}

	}

	# die "implement checksum\n";

}

################################################################################
# register our tool within the main module
################################################################################

OCBNET::Webmerge::Tool::register('crc-check', \&checksum, + 99);

################################################################################
################################################################################
1;
