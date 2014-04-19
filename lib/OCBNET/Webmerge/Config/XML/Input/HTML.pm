################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Input::HTML;
################################################################################
use base qw(
	OCBNET::Webmerge::Input::HTML
	OCBNET::Webmerge::Config::XML::Input
);
################################################################################

use strict;
use warnings;

################################################################################
# route some method to specific packages
# otherwise they would be consumed by others
################################################################################

sub path { &OCBNET::Webmerge::Config::XML::Input::path }
sub parent { &OCBNET::Webmerge::Config::XML::Input::parent }

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT::HTML' }

################################################################################
################################################################################
1;