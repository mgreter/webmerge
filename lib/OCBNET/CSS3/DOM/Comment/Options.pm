###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::DOM::Comment::Options;
####################################################################################################

use strict;
use warnings;

####################################################################################################

use OCBNET::CSS3::Regex::Base;

####################################################################################################

# plug into comment reading
# parse all possible options
sub reader
{

	# get input variables
	my ($self, $text) = @_;

	# trim the comment (remove opener/closer)
	$text =~ s/(?:\A\s*\/+\*+|\*+\/+\s*\z)//gs;

	# try to parse key/value pairs (pretty unstrict, but has loose syntax)
	while ($text =~ m/(?:\A|;+)\s*($re_identifier)\s*\:\s*(.*?)\s*(?:\z|;+)/g)
	{
		if ($self->parent && $self->parent->options)
		{ $self->parent->options->set($1, $2); }
	}

	# instance
	return $self

}
# EO sub reader

####################################################################################################
# register additional reader for comments
####################################################################################################

OCBNET::CSS3::DOM::Comment::register(\&reader);

####################################################################################################
####################################################################################################
1;
