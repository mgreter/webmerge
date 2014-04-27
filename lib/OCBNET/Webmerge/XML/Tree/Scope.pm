################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# XML scope is a node that connects to a config scope
# Config scopes inherit settings from parent scopes
################################################################################
package OCBNET::Webmerge::XML::Tree::Scope;
################################################################################
use base qw(OCBNET::Webmerge::Object);
use base qw(OCBNET::Webmerge::Tree::Scope);
use base qw(OCBNET::Webmerge::XML::Tree::Node);
################################################################################

use strict;
use warnings;

################################################################################
# register additional xml tags
################################################################################

$OCBNET::Webmerge::XML::parser{'block'} = __PACKAGE__;
$OCBNET::Webmerge::XML::parser{'merge'} = __PACKAGE__;

################################################################################
1;
