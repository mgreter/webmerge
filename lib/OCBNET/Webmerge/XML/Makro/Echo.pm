################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::XML::Makro::Echo;
################################################################################
use base qw(OCBNET::Webmerge::Makro::Echo);
use base qw(OCBNET::Webmerge::XML::Tree::Node);
################################################################################
$OCBNET::Webmerge::XML::parser{'echo'} = __PACKAGE__;
################################################################################
################################################################################
1;
