################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File::HTML;
################################################################################
use base OCBNET::Webmerge::IO::File;
################################################################################

use strict;
use warnings;

################################################################################
use IO::HTML qw(sniff_encoding);
################################################################################

sub open
{
	# get arguments
	my ($node, $mode) = @_;
	# get path for node
	my $path = $node->path;
	# open the filehandle in raw mode
	my $fh = $node->SUPER::open($mode);
	# sniff the encoding for the html file
	my $encoding = sniff_encoding($fh, $path);
	# store sniffed encoding on file node
	$node->{'encoding'} = $encoding if $encoding;
	# put a debug message to the console about the encoding
	# print "read html with encoding: ", $node->{'encoding'}, "\n";
	# return filehandle
	return $fh;
}

################################################################################
################################################################################
1;