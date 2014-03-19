################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Input::CSS;
################################################################################
use base qw(
	OCBNET::Webmerge::Config::XML::Input
	OCBNET::Webmerge::IO::File::CSS
);
################################################################################

use strict;
use warnings;

################################################################################
use IO::CSS qw(sniff_encoding);
################################################################################

sub open
{
	# get arguments
	my ($node, $mode) = @_;
	# get path for node
	my $path = $node->path;
	# open the filehandle in raw mode
	my $fh = $node->SUPER::open($mode);
	# sniff the encoding for the css file
	my $encoding = sniff_encoding($fh, $path);
	# store sniffed encoding on file node
	$node->{'encoding'} = $encoding if $encoding;
	# return filehandle
	return $fh;
}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT::CSS' }

################################################################################
################################################################################
1;