################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::XML::Merge;
################################################################################
use base qw(OCBNET::Webmerge::Merge);
use base qw(OCBNET::Webmerge::XML::Tree::Scope);
################################################################################
$OCBNET::Webmerge::XML::parser{'js'} = __PACKAGE__;
$OCBNET::Webmerge::XML::parser{'css'} = __PACKAGE__;
################################################################################
################################################################################
1;