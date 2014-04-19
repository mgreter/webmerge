################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Output::HTML;
################################################################################
use base qw(
	OCBNET::Webmerge::Config::XML::Output
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
	die "open html out";
	# get arguments
	my ($node, $mode) = @_;
	# get path for node
	my $path = $node->path;
	# open the filehandle in raw mode
	my $fh = $node->SUPER::open($mode);
	# sniff the encoding for the css file
	# my $encoding = sniff_encoding($fh, $path);
	# store sniffed encoding on file node
	# $node->{'encoding'} = $encoding if $encoding;
	# return filehandle
	return $fh;
}

################################################################################
# render output context
################################################################################

sub render
{

	return \ "render html";

}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'OUTPUT::HTML' }

################################################################################
################################################################################
1;