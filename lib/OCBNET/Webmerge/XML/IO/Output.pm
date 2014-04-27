################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::XML::IO::Output;
################################################################################
use base qw(OCBNET::Webmerge::IO::Output);
use base qw(OCBNET::Webmerge::XML::Tree::Node);
################################################################################
#use base qw(OCBNET::Webmerge::Config::Output);
################################################################################

use strict;
use warnings;

################################################################################

#require OCBNET::Webmerge::Config::XML::Output::JS;
#require OCBNET::Webmerge::Config::XML::Output::CSS;
#require OCBNET::Webmerge::Config::XML::Output::HTML;
#require OCBNET::Webmerge::Config::XML::Output::ANY;

################################################################################
# just connect the namespaces
################################################################################

$OCBNET::Webmerge::XML::parser{'output'} = __PACKAGE__;

################################################################################
################################################################################
1;