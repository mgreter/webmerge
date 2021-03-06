################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::File::HTML;
################################################################################
use base qw(OCBNET::Webmerge::IO::File::TXT);
################################################################################
use base qw(OCBNET::IO::File::HTML);
################################################################################

use strict;
use warnings;

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'FILE::HTML' }

# return file type
sub ftype { 'html' }

################################################################################
################################################################################
1;
