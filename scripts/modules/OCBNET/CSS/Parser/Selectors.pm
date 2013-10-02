###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# regular expressions to match css2/css3 selectors
####################################################################################################
package OCBNET::CSS::Parser::Selectors;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# define our version string
BEGIN { $OCBNET::CSS::Parser::Selectors::VERSION = "0.8.2"; }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw($re_css_selector_rules); }

# define our functions than can be exported
BEGIN { our @EXPORT_OK = qw($re_css_selector_rule $re_options); }

####################################################################################################

use OCBNET::CSS::Parser::Base;

####################################################################################################

# create matchers for the various css selector types
our $re_css_id = qr/\#$re_css_name/; # select single id
our $re_css_tag = qr/(?:$re_css_name|\*)/; # select single tag
our $re_css_class = qr/\.$re_css_name/; # select single class
our $re_css_pseudo = qr/\:{1,2}$re_css_name/; # select single pseudo

# select attributes and its content with advanced css2/css3 selectors
our $re_css_attr = qr/\[$re_css_name\s*(?:[\~\^\$\*\|]?=\s*(?:\'$re_apo\'|\"$re_quot\"|[^\)]*))?\]/;

####################################################################################################

# create expression to match a single rule
# example : DIV#id.class1.class2:hover
our $re_css_selector = qr/(?:
	  \*
	| $re_css_attr* $re_css_pseudo+
	| $re_css_class+ $re_css_attr* $re_css_pseudo*
	| $re_css_id $re_css_class* $re_css_attr* $re_css_pseudo*
	| $re_css_tag $re_css_id? $re_css_class* $re_css_attr* $re_css_pseudo*
)/x;

####################################################################################################

# create expression to match complex rules
# example : #id DIV.class FORM A:hover
our $re_css_selector_rule = qr/$re_css_selector(?:(?:\s*[\>\+\~]\s*|\s+)$re_css_selector)*/;

####################################################################################################

# create expression to match multiple complex rules
# example : #id DIV.class FORM A:hover, BODY DIV.header
our $re_css_selector_rules = qr/$re_css_selector_rule(?:\s*,\s*$re_css_selector_rule)*/;

####################################################################################################
####################################################################################################
1;