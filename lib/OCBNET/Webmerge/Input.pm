################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Input;
################################################################################
use base OCBNET::Webmerge::File;
################################################################################

use strict;
use warnings;

################################################################################
# no implementation yet
################################################################################

sub import { $_[0]->logFile('import') }

################################################################################
# read only
################################################################################

sub revert { }
sub commit { }

################################################################################
# render input for output (target)
################################################################################

sub render
{

	# get arguments
	my ($input, $output) = @_;

	# get the target for the include
	my $target = lc ($output->target || 'join');

	# implement some special target handling
	return $input->include($output) if ($target eq 'dev');
	return $input->license($output) if ($target eq 'license');

	# otherwise read the input
	${$input->contents};

}

################################################################################

sub inputs
{

	# get arguments
	my ($input) = @_;

	# we are a single input if we have no ref
	return $input unless $input->attr('ref');

	# to be implemented
	die "have a input ref";

}

################################################################################
################################################################################
1;