################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File::TXT;
################################################################################
use base qw(OCBNET::Webmerge::IO::File);
################################################################################

use strict;
use warnings;

################################################################################
# force newline at the end of the content
################################################################################

sub contents
{
	# get result from parent implementation
	my $content = shift->SUPER::contents(@_);
	# return result if content is undefined
	return $content unless defined $content;
	# return result if content is empty
	return $content unless length $content;
	# return if there is a newline at the end
	return $content if $content =~ m/^\s*\z/;
	# add newline to original and return
	${$content} .= "\n"; return $content;
}

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'FILE::TXT' }

################################################################################
################################################################################
1;
