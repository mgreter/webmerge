################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Tool::Execute;
################################################################################

use strict;
use warnings;

################################################################################
use List::MoreUtils qw(uniq);
################################################################################

sub execute
{
	# get arguments
	my ($webmerge, $blocks) = @_;
	# call execute on all unique blocks
	$_->execute foreach (uniq @{$blocks});
}

################################################################################
# register our tool within the main module
################################################################################

OCBNET::Webmerge::Tool::register('merge', \&execute, 0);

################################################################################
################################################################################
1;
