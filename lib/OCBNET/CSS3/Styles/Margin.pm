###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Styles::Margin;
####################################################################################################

use strict;
use warnings;

####################################################################################################
# import regular expressions
####################################################################################################

use OCBNET::CSS3::Regex::Numbers;

####################################################################################################
# register longhand properties for margin
####################################################################################################

OCBNET::CSS3::Styles::register('margin-top', $re_length, '0');
OCBNET::CSS3::Styles::register('margin-left', $re_length, '0');
OCBNET::CSS3::Styles::register('margin-right', $re_length, '0');
OCBNET::CSS3::Styles::register('margin-bottom', $re_length, '0');

####################################################################################################
# register shorthand property for margin
####################################################################################################

OCBNET::CSS3::Styles::register('margin',
{
	'ordered' =>
	# needed in order
	[
		# always needed
		[ 'margin-top' ],
		# additional optional values
		# may evaluate to other value
		[ 'margin-right', 'margin-top'],
		[ 'margin-bottom', 'margin-top'],
		[ 'margin-left', 'margin-right']
	]
});

####################################################################################################
####################################################################################################
1;
