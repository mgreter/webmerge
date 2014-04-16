################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Input::CSS;
################################################################################
use base qw(
	OCBNET::Webmerge::Config::XML::Input
	OCBNET::Webmerge::IO::File::CSS
	OCBNET::Webmerge::Input::CSS
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
	# put a debug message to the console about the encoding
	print "open css with encoding: ", $node->{'encoding'}, "\n";
	# return filehandle
	return $fh;
}

################################################################################
# route some method to specific packages
# otherwise they would be consumed by others
################################################################################

sub deps { &OCBNET::Webmerge::Input::CSS::deps }

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT::CSS' }

################################################################################
################################################################################
1;