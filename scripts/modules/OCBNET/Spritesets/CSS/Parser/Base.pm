###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
package OCBNET::Spritesets::CSS::Parser::Base;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# define our version string
BEGIN { $OCBNET::Spritesets::CSS::Parser::Base::VERSION = "0.70"; }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw($re_apo $re_quot $re_css_name $re_number $re_percent $re_byte); }

# define our functions than can be exported
BEGIN { our @EXPORT_OK = qw($re_comment $re_number_neg $re_number_pos); }

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
our $re_number_neg = qr/\-[0-9]*\.?[0-9]+/s;
our $re_number_pos = qr/\+?[0-9]*\.?[0-9]+/s;

# match a percent value
#**************************************************************************************************
our $re_percent = qr/$re_number\%/s;

# match a number from 0 to 255 (strict match)
#**************************************************************************************************
our $re_byte = qr/(?:0|[1-9]\d?|1\d{2}|2(?:[0-4]\d|5[0-5]))/s;

####################################################################################################
####################################################################################################
1;