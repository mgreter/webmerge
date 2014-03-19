################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Input::HTML;
################################################################################
use base qw(
	OCBNET::Webmerge::Config::XML::Input
	OCBNET::Webmerge::IO::File::HTML
);
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
	# sniff and store the encoding for the css file
	$node->{'encoding'} = sniff_encoding($fh, $path);
	# return filehandle
	return $fh;
}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT::HTML' }

################################################################################
################################################################################
1;