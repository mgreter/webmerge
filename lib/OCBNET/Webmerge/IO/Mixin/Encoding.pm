################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::Encoding;
################################################################################

use strict;
use warnings;

################################################################################
use Encode qw();
################################################################################


# encode internal data into given encoding
# do not alter data if encoding is raw or bytes
# ******************************************************************************
sub encode
{

	# get arguments
	my ($file, $data) = @_;

	# skip this step if encoding indicates raw or byte data
	return \ "${$data}" if $file->encoding =~ m/^\:?(?:raw|bytes)$/i;

	# call decoder to translate from encoding
	return \ Encode::encode($file->encoding, ${$data});

}

# decode external data from given encoding
# do not alter data if encoding is raw or bytes
# ******************************************************************************
sub decode
{

	# get arguments
	my ($file, $data) = @_;

	# skip this step if encoding indicates raw or byte data
	return \ "${$data}" if $file->encoding =~ m/^\:?(?:raw|bytes)$/i;

	# call decoder to translate from encoding
	return \ Encode::decode($file->encoding, ${$data});

}

################################################################################
################################################################################
1;

