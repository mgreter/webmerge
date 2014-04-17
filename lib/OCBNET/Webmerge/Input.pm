################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Input;
################################################################################

use strict;
use warnings;

################################################################################
################################################################################

# define the template for the script includes
# don't care about doctype versions, dev only
our $css_include_tmpl = '@import url(\'%s\');' . "\n";

################################################################################
# generate a css include (@import)
# add support for data or reference id
################################################################################

sub include
{

	# get arguments
	my ($input, $output) = @_;

	# get a unique path with added fingerprint
	my $path = $input->fingerprint($output->target);

	# return the script include string
	return sprintf($css_include_tmpl, $path);

}

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

	# otherwise read the inpute
	return ${$input->read};

}

################################################################################
################################################################################
1;