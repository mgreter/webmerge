################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Optimize;
################################################################################
use base 'OCBNET::Webmerge::Config::XML::Node';
################################################################################
require OCBNET::Webmerge::Config::XML::Optimize::TXT;
require OCBNET::Webmerge::Config::XML::Optimize::PNG;
require OCBNET::Webmerge::Config::XML::Optimize::JPG;
require OCBNET::Webmerge::Config::XML::Optimize::GIF;
require OCBNET::Webmerge::Config::XML::File::Optimize;
################################################################################

use strict;
use warnings;

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'OPTIMIZE' }

################################################################################
################################################################################
1;