################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Input;
################################################################################
use base qw(OCBNET::Webmerge::IO::Files);
################################################################################

use strict;
use warnings;

################################################################################
# load additional modules
################################################################################

# require OCBNET::Webmerge::Input::JS;
# require OCBNET::Webmerge::Input::CSS;
# require OCBNET::Webmerge::Input::HTML;

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
	return \ $input->include($output) if ($target eq 'dev');
	return \ $input->license($output) if ($target eq 'license');

	# otherwise read the input
	$input->contents;

}

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'INPUT' }

################################################################################
################################################################################
1;
