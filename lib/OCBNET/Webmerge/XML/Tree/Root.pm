################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# XML root is a scope that has no parent
# Stop certain cascading methods here
################################################################################
package OCBNET::Webmerge::XML::Tree::Root;
################################################################################
use base qw(OCBNET::Webmerge::Object);
use base qw(OCBNET::Webmerge::Tree::Root);
use base qw(OCBNET::Webmerge::XML::Tree::Scope);
################################################################################
################################################################################
1;
