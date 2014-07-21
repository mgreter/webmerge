###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::Styles::References;
####################################################################################################

use strict;
use warnings;

####################################################################################################
# import regular expressions
####################################################################################################

use OCBNET::CSS3::Regex::Base;

# parse comments if module is loaded
#**************************************************************************************************
use OCBNET::CSS3::DOM::Comment::Options;

####################################################################################################
# register longhand properties for references
# blocks with an id can be referenced by other blocks
# they act as a parent to further resolve styles/options
# you may declare multiple references as a comma separated list
####################################################################################################

OCBNET::CSS3::Styles::register('css-id', $re_identifier);
OCBNET::CSS3::Styles::register('css-ref', $re_identifier);

####################################################################################################
####################################################################################################
1;
