################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Runner::Checksum;
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

			unless (-f $output->path)
			{

				$_[0]->err(substr $output->path, - 45);
				$_[0]->err("crc check failed as the file does not exist");

			}
			else
			{

				# write out changes
				$block->commit(1);

				require OCBNET::Webmerge::IO::CRC;
				# create path to store checksum of this output

				my $checksum = OCBNET::Webmerge::IO::CRC->new($output);

				# loosely couple the nodes together
				$checksum->{'parent'} = $output;
				# do a check against the crc content
				my $crc = $output->check($checksum->read);

			}
		}

	}

	# die "implement checksum\n";

}

################################################################################
# register our tool within the main module
################################################################################

OCBNET::Webmerge::Runner::register('crc-check', \&checksum, + 99);

################################################################################
################################################################################
1;
