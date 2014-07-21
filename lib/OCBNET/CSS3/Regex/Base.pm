###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Regex::Base;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that can be exported
BEGIN { our @EXPORT_OK = qw($re_url $re_uri $re_import fromUrl wrapUrl); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw($re_apo $re_quot $re_identifier $re_string $re_vendors unquot); }

####################################################################################################
# base regular expressions
####################################################################################################

# match text in apos or quotes
#**************************************************************************************************
our $re_apo = qr/(?:[^\'\\]+|\\.)*/s;
our $re_quot = qr/(?:[^\"\\]+|\\.)*/s;

# match an identifier or name
#**************************************************************************************************
our $re_identifier = qr/\b[_a-zA-Z][_a-zA-Z0-9\-]*/s;

# match a text (can be identifier or quoted string)
#**************************************************************************************************
our $re_string = qr/(?:$re_identifier|\"$re_quot\"|\'$re_apo\')/is;

# regular expression to match any url
#**************************************************************************************************
our $re_url = qr/url\((?:\'$re_apo\'|\"$re_quot\"|[^\)]*)\)/s;

# match specific vendors
#**************************************************************************************************
our $re_vendors = qr/(?:o|ms|moz|webkit)/is;

####################################################################################################

# parse urls out of the css file
# match will be saved as $+{uri}
our $re_uri = qr/url\(\s*(?:
	\s*\"(?!data:)(?<uri>$re_quot)\" |
	\s*\'(?!data:)(?<uri>$re_apo)\' |
	(?![\"\'])\s*(?!data:)(?<uri>[^\)]*)
)\s*\)/xi;

####################################################################################################

# parse urls out of the css file
# match will be saved as $+{uri}
our $re_import = qr/\@import\s*(?:
	url\(\s*(?:
		\s*\"(?!data:)(?<url>$re_quot)\" |
		\s*\'(?!data:)(?<url>$re_apo)\' |
		(?![\"\'])\s*(?!data:)(?<url>[^\)]*)
	)\) | (?:
		\s*\"(?!data:)(?<uri>$re_quot)\" |
		\s*\'(?!data:)(?<uri>$re_apo)\' |
		(?![\"\'])\s*(?!data:)(?<uri>[^\s;]*)
	))
\s*;?/xi;

####################################################################################################

# a very plain and simply unquote function
# implement correctly once we actually find the specs
# although we could add some known escaping sequences
#**************************************************************************************************
sub unquot
{
	# get the string
	my $txt = $_[0];
	# replace hexadecimal representation
	# http://www.w3.org/International/questions/qa-escapes
	$txt =~ s/\\([0-9A-F]{2,6})\s?/chr hex $1/eg;
	# replace escape character
	$txt =~ s/\\(.)/$1/g;
	# return result
	$txt;
}

####################################################################################################
####################################################################################################
1;
