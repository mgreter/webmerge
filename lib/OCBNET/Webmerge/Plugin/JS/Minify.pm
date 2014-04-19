################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Plugin::JS::Minify;
################################################################################

use strict;
use warnings;

################################################################################

# plugin namespace
my $ns = 'js::minify';

################################################################################
# alter data in-place
################################################################################

sub process
{

	# get arguments
	my ($file, $data) = @_;

	# module is optional
	require JavaScript::Minifier;

	# call minifer and store data
	${$data} = JavaScript::Minifier::minify('input' => ${$data});

	# check if minfier had any issues or errors
	die "CSS::Minfier had an error" unless defined ${data};

	# return reference
	return $data;

}
# EO process

################################################################################
# called via perl loaded
################################################################################

sub import
{
	# get arguments
	my ($fqns, $node, $webmerge) = @_;
	# register our processor to document
	$node->document->processor($ns, \&process);
}

################################################################################
################################################################################
1;