################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::MAP;
################################################################################
use base OCBNET::Webmerge::IO::EXT;
################################################################################

use strict;
use warnings;

################################################################################

# break call loop
sub checksum { $_[1] }
sub sourcemap { $_[1] }
sub extension { 'map' }

################################################################################
################################################################################

sub render
{
	die "fuck";
}

################################################################################
################################################################################
1;
