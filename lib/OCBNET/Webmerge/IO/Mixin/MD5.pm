################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::MD5;
################################################################################

use strict;
use warnings;

################################################################################
# calculate checksum
################################################################################
use Digest::MD5 qw();
use Encode qw(encode);
################################################################################

sub md5sum
{

	# get the file node
	my ($file, $data, $raw) = @_;

	# create a new digest object
	my $md5 = Digest::MD5->new;

	# load data if nothing has been passed
	$data = $file->load unless defined $data;
Carp::confess unless $data;


	# read from node if no data is passed
	$data = $file->contents unless $data;

	# convert data into encoding if we have no raw data
	$data = \ encode($file->encoding, ${$data}) unless $raw;

	# add raw data and return final digest
	return uc($md5->add(${$data})->hexdigest);

}

sub md5short
{

	# get the optionaly configured fingerprint length
	my $len = $_[0]->option('fingerprint-length') || 12;

	# return a short configurable length md5sum
	return substr($_[0]->md5sum($_[1], $_[2]), 0, $len);

}

###############################################################################
# is different from md5sum for css files
# as we remove the charset declaration on load
###############################################################################

sub crc { $_[0]->load unless $_[0]->{'crc'}; $_[0]->{'crc'} }

################################################################################
################################################################################
1;

