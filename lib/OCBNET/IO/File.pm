################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::IO::File;
################################################################################
use base qw(IO::File);
################################################################################

use strict;
use warnings;

################################################################################
################################################################################

sub open
{
	# get arguments
	my ($fh) = shift;
	# dispatch open (abort on error)
	my $rv = $fh->SUPER::open(@_) || return;
	# sniff the encoding for the css file
	my $encoding = $fh->sniff_encoding($_[0]);
	# store sniffed encoding on file node
	if ($fh && UNIVERSAL::can($fh, 'encoding'))
	{ $fh->encoding = $encoding if $encoding; }
	# return filehandle
	return $fh;
}

################################################################################
# handle encoding on glob
################################################################################

sub encoding : lvalue
{
	# get handle
	my $fh = $_[0];
	# store to glob
	${*$fh}{'encoding'};
}

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
