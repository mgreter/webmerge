###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
package OCBNET::CSS::Parser::Base;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# define our version string
BEGIN { $OCBNET::CSS::Parser::Base::VERSION = "0.70"; }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw($re_apo $re_quot $re_css_name $re_number $re_percent $re_byte); }

# define our functions than can be exported
BEGIN { our @EXPORT_OK = qw($re_comment uncomment fromPx fromUrl fromPosition); }

####################################################################################################
# base regular expressions
####################################################################################################

# match text in apos or quotes
#**************************************************************************************************
our $re_apo = qr/(?:[^\'\\]+|\\.)*/s;
our $re_quot = qr/(?:[^\"\\]+|\\.)*/s;

# match a multiline comment
#**************************************************************************************************
our $re_comment = qr/\/\*\s*(.*?)\s*\*\//s;

# match a css identifier name
#**************************************************************************************************
our $re_css_name = qr/[_a-zA-Z][_a-zA-Z0-9\-]*/;

# match (floating point) numbers
#**************************************************************************************************
our $re_number = qr/[\-\+]?[0-9]*\.?[0-9]+/s;
# our $re_number_neg = qr/\-[0-9]*\.?[0-9]+/s;
# our $re_number_pos = qr/\+?[0-9]*\.?[0-9]+/s;

# match a percent value
#**************************************************************************************************
our $re_percent = qr/$re_number\%/s;

# match a number from 0 to 255 (strict match)
#**************************************************************************************************
our $re_byte = qr/(?:0|[1-9]\d?|1\d{2}|2(?:[0-4]\d|5[0-5]))/s;

####################################################################################################
# some helper functions
####################################################################################################

# parse dimension from pixel
#**************************************************************************************************
sub uncomment
{
	# remove comment from actual value
	$_[0] =~ s/$re_comment//gm;
	# return the given value
	return $_[0];
}
# EO sub uncomment

# parse dimension from pixel
#**************************************************************************************************
sub fromPx
{
	# return undef if nothing passed
	return unless defined $_[0];
	# parse number via regular expression
	$_[0] =~ m/($re_number)px/i ? $1 : $_[0];
}

# parse an url
#**************************************************************************************************
sub fromUrl
{
	# check for css url pattern (call again to unwrap quotes)
	return fromUrl($1) if $_[0] =~ m/^\s*url\(\s*(.*?)\s*\)\s*$/m;
	# unwrap quotes if there are any
	return $1 if $_[0] =~ m/^\"(.*?)\"\z/m;
	return $1 if $_[0] =~ m/^\'(.*?)\'\z/m;
	# return same as given
	return $_[0];
}

# parse background position
#**************************************************************************************************
sub fromPosition
{

	# get position string
	my ($position) = @_;

	# default to left/top position
	return 0 unless (defined $position);

	# allow keywords for left and top position
	return 0 if ($position =~ m/^(?:top|left)$/i);

	# return the parsed pixel number if matched
	return $1 if ($position =~ m/^($re_number)(?:px)?$/i);

	# right/bottom are the only valid keywords
	# for the position for most other functions
	return 'right' if ($position =~ m/^right$/i);
	return 'bottom' if ($position =~ m/^bottom$/i);

	# die with a fatal error for invalid positions
	die "unknown background position: <$position>";

}

####################################################################################################
####################################################################################################
1;