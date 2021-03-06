###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::DOM::Whitespace;
####################################################################################################

use strict;
use warnings;

####################################################################################################
use base 'OCBNET::CSS3';
####################################################################################################

# static getter
#**************************************************************************************************
sub type { return 'whitespace' }

####################################################################################################

# add basic extended type with highest priority
#**************************************************************************************************
unshift @OCBNET::CSS3::types, [
	qr//is,
	'OCBNET::CSS3::DOM::Whitespace',
	sub { $_[0] =~ m/\A\s+\z/is }
];

####################################################################################################
####################################################################################################
1;
