###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Styles::Padding;
####################################################################################################

use strict;
use warnings;

####################################################################################################
# import regular expressions
####################################################################################################

use OCBNET::CSS3::Regex::Numbers;

####################################################################################################
# register longhand properties for padding
####################################################################################################

OCBNET::CSS3::Styles::register('padding-top', $re_length, '0');
OCBNET::CSS3::Styles::register('padding-left', $re_length, '0');
OCBNET::CSS3::Styles::register('padding-right', $re_length, '0');
OCBNET::CSS3::Styles::register('padding-bottom', $re_length, '0');

####################################################################################################
# register shorthand property for padding
####################################################################################################

OCBNET::CSS3::Styles::register('padding',
{
	'ordered' =>
	# needed in order
	[
		# always needed
		[ 'padding-top' ],
		# additional optional values
		# may evaluate to other value
		[ 'padding-right', 'padding-top'],
		[ 'padding-bottom', 'padding-top'],
		[ 'padding-left', 'padding-right']
	]
});

####################################################################################################
####################################################################################################
1;
