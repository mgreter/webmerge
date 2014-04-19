################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Plugin::CSS::Compile;
################################################################################

use strict;
use warnings;

################################################################################

# plugin namespace
my $ns = 'css::compile';

################################################################################
# alter data in-place
################################################################################

sub process
{

	# get arguments
	my ($file, $data) = @_;

	# module is optional
	require OCBNET::CSS3::Minifier;

	# define options hash for minifier
	my $options = { 'level' => 9, 'pretty' => 0 };

	# minify via our own css minifyer
	${data} = OCBNET::CSS3::Minifier::minify(${data}, $options);

	# check if minfier had any issues or errors
	die "OCBNET::CSS3::Minifier had an error" unless defined ${data};

}

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