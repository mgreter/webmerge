################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::XML::IO::Input;
################################################################################
use base qw(OCBNET::Webmerge::IO::Input);
use base qw(OCBNET::Webmerge::XML::Tree::Node);
################################################################################
#use base qw(OCBNET::Webmerge::Config::Input);
#use base qw(OCBNET::Webmerge::Config::XML::File);
################################################################################

use strict;
use warnings;

################################################################################

#require OCBNET::Webmerge::Config::XML::Input::JS;
#require OCBNET::Webmerge::Config::XML::Input::CSS;
#require OCBNET::Webmerge::Config::XML::Input::HTML;
#require OCBNET::Webmerge::Config::XML::Input::ANY;

################################################################################
# just connect the namespaces
################################################################################

$OCBNET::Webmerge::XML::parser{'input'} = __PACKAGE__;
$OCBNET::Webmerge::XML::parser{'suffix'} = __PACKAGE__;
$OCBNET::Webmerge::XML::parser{'prefix'} = __PACKAGE__;
$OCBNET::Webmerge::XML::parser{'append'} = __PACKAGE__;
$OCBNET::Webmerge::XML::parser{'prepend'} = __PACKAGE__;

################################################################################
################################################################################
1;