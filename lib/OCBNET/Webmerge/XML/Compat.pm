################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::XML::Compat;
################################################################################

use strict;
use warnings;

################################################################################
# define some tags currently without implementation
################################################################################

$OCBNET::Webmerge::XML::parser{'arg'} =
$OCBNET::Webmerge::XML::parser{'echo'} =
$OCBNET::Webmerge::XML::parser{'eval'} =
$OCBNET::Webmerge::XML::parser{'feature'} =
$OCBNET::Webmerge::XML::parser{'test'} =
$OCBNET::Webmerge::XML::parser{'enable'} =
$OCBNET::Webmerge::XML::parser{'disable'} =
$OCBNET::Webmerge::XML::parser{'copy'} =
$OCBNET::Webmerge::XML::parser{'mkdir'} =
$OCBNET::Webmerge::XML::parser{'txt'} =
$OCBNET::Webmerge::XML::parser{'gif'} =
$OCBNET::Webmerge::XML::parser{'jpg'} =
$OCBNET::Webmerge::XML::parser{'gz'} =
$OCBNET::Webmerge::XML::parser{'zip'} =
$OCBNET::Webmerge::XML::parser{'png'} =
$OCBNET::Webmerge::XML::parser{'mng'} =
$OCBNET::Webmerge::XML::parser{'detect'} =
$OCBNET::Webmerge::XML::parser{'include'} =
$OCBNET::Webmerge::XML::parser{'input'} =
$OCBNET::Webmerge::XML::parser{'append'} =
$OCBNET::Webmerge::XML::parser{'prepend'} =
$OCBNET::Webmerge::XML::parser{'output'} =
'OCBNET::Webmerge::XML::Tree::Node';

$OCBNET::Webmerge::XML::parser{'headinc'} =
$OCBNET::Webmerge::XML::parser{'optimize'} =
$OCBNET::Webmerge::XML::parser{'embedder'} =
$OCBNET::Webmerge::XML::parser{'prepare'} =
$OCBNET::Webmerge::XML::parser{'finish'} =
'OCBNET::Webmerge::XML::Tree::Scope';

$OCBNET::Webmerge::XML::parser{'file'} =
'OCBNET::Webmerge::XML::IO::Files';

$OCBNET::Webmerge::XML::parser{'prerun'} =
$OCBNET::Webmerge::XML::parser{'postrun'} =
'OCBNET::Webmerge::XML::Makro::Exec';

################################################################################
################################################################################
1;