###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Regex::Comments;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw($re_comment uncomment comments); }

####################################################################################################
# base regular expressions
####################################################################################################

# regex found on the w3.org's css grammar page
# ***************************************************************************************
our $re_comment = qr/\/\*[^*]*\*+([^\/*][^*]*\*+)*\//;

####################################################################################################

# uncomment a text
sub uncomment ($)
{

	# get the text from args
	my ($text) = join("", @_);

	# remove all comments from text
	$text =~ s/$re_comment//gm;

	# return result
	return $text;

}
# EO sub uncomment

####################################################################################################

# get comments
sub comments ($)
{

	# collect comments
	my (@comments);

	# get the text from args
	my ($text) = join("", @_);

	# collect all comments inside the given text node
	push @comments, $1 while $text =~ m/($re_comment)/gs;

	# remove comment opener and closer from strings
	s/(?:\A\s*\/+\*+\s*|\s*\*+\/+\s*\z)//g foreach @comments;

	# return result
	return @comments;

}
# EO sub uncomment

####################################################################################################
####################################################################################################
1;
