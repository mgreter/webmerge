################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::Checksum;
################################################################################

use strict;
use warnings;

################################################################################
# append the checksum to data
################################################################################
use OCBNET::Webmerge::IO::CRC;
################################################################################

sub checksum
{

	# get passed input arguments
	my ($output, $data, $smap, $options) = @_;

	# declare local variables and collect all inputs
	my ($inputs, @md5sum, @inputs) = ($output->inputs);

	# process all input items collected on output node
	foreach my $input (@{$inputs->[1]}, @{$inputs->[0]}, @{$inputs->[2]})
	{
		# import the file
		$input->contents;
		# get further dependencies (aka css imports)
		foreach my $file ($input, $input->collect('file'))
		{
			# get md5sum for input and append to sums
			push @md5sum, my $md5sum = $file->{'crc'};
			# create checksum for every input file for final crc file (also handle inline text nodes)
			unless ($file->attr('path')) { push @inputs, join(': ', '>' . $file->selector, $md5sum) }
			else { push @inputs, join(': ', $file->localurl($output->dirname), $md5sum); }
		}
	}

	# create an md5 out of all joined input md5s
	my $md5_inputs = $output->md5sum(\join("::", @md5sum));

	# append the crc of all joined checksums
	${$data} .= "\n/* crc: " . $md5_inputs . " */\n"; # if $config->{'crc-comment'};

	# store to options for signature use
	$options->{'crc-inputs'} = \ @inputs;
	$options->{'md5-inputs'} = $md5_inputs;

}

################################################################################
# create the checksum file
################################################################################
use OCBNET::Webmerge::IO::CRC;
################################################################################

sub signature
{

	# get passed input arguments
	my ($output, $data, $smap, $options) = @_;

	# get from options for signature use
	my @inputs = @{$options->{'crc-inputs'}};
	my $md5_inputs = $options->{'md5-inputs'};

	# calculate final md5sum (convert data)
	my $crc = $output->md5sum($data) . "\n\n";
	# add checksum over all inputs
	$crc .= $md5_inputs . "\n";
	# add list of crcs of all sources
	$crc .= join("\n", @inputs) . "\n";

	# create path to store checksum of this output
	my $checksum = OCBNET::Webmerge::IO::CRC->new($output);

	# finally write the crc
	$checksum->write(\$crc);

}

################################################################################
################################################################################
1;
