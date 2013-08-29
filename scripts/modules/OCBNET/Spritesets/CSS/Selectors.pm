####################################################################################################
####################################################################################################
package OCBNET::Spritesets::CSS::Selectors;
####################################################################################################

####################################################################################################

# define our version string
# BEGIN { $OCBNET::Spritesets::CSS::Selectors::VERSION = "0.70"; }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw($re_css_selector_rules); }

# define our functions than can be exported
BEGIN { our @EXPORT_OK = qw($re_css_selector_rule); }


####################################################################################################

use OCBNET::Spritesets::CSS::Base;

####################################################################################################

# create matchers for the various css selector types
our $re_css_id = qr/\#$re_css_name/; # select single id
our $re_css_tag = qr/(?:$re_css_name|\*)/; # select single tag
our $re_css_class = qr/\.$re_css_name/; # select single class
our $re_css_pseudo = qr/\:{1,2}$re_css_name/; # select single pseudo

our $re_css_attr = qr/\[$re_css_name\s*(?:[\~\^\$\*\|]?=\s*(?:\'$re_apo\'|\"$re_quot\"|[^\)]*))?\]/; # select single pseudo

# create expression to match a single rule
# example : DIV#id.class1.class2:hover
our $re_css_selector = qr/(?:
	  \*
	| $re_css_attr* $re_css_pseudo+
	| $re_css_class+ $re_css_attr* $re_css_pseudo*
	| $re_css_id $re_css_class* $re_css_attr* $re_css_pseudo*
	| $re_css_tag $re_css_id? $re_css_class* $re_css_attr* $re_css_pseudo*
)/x;

# create expression to match complex rules
# example #id DIV.class FORM A:hover
our $re_css_selector_rule = qr/$re_css_selector(?:(?:\s*[\>\+\~]\s*|\s+)$re_css_selector)*/;

# create expression to match multiple complex rules
# example #id DIV.class FORM A:hover, BODY DIV.header
our $re_css_selector_rules = qr/$re_css_selector_rule(?:\s*,\s*$re_css_selector_rule)*/;

our $re_option = qr/\w(?:\w|-)*\s*:\s*[^;]+;/;
our $re_options = qr/$re_option(?:\s*$re_option)*/m;

####################################################################################################
####################################################################################################
1;