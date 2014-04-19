################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Plugin::CSS::Lint;
################################################################################

use strict;
use warnings;

################################################################################

sub init
{
	die "called init";
}

################################################################################

# plugin namespace
my $ns = 'css::lint';

################################################################################
# alter data in-place
################################################################################

sub process
{

	# get arguments
	my ($data, $file, $scope) = @_;

	# parse sheet and fetch stats
	my $stats = $file->sheet($data)->stats;

	# get array references from stats
	my $imports = $stats->{'imports'} || [];
	my $selectors = $stats->{'selectors'} || [];

	# print a log message to the console
	my $tmpl = 'CSSLINT: %s selectors and %s imports';
	$file->log(sprintf $tmpl, scalar(@{$selectors}), scalar(@{$imports}));

	# KB 262161 outlines the maximum number of stylesheets
	# and rules supported by Internet Explorer 6 to 9.
	# - A sheet may contain up to 4095 rules
	# - A sheet may @import up to 31 sheets
	# - @import nesting supports up to 4 levels deep
	warn "Too many imports in css file for IE\n" if (scalar(@{$imports}) > 30);
	warn "Too many selectors in css file for IE\n" if (scalar(@{$selectors}) > 4000);
	sleep 2 if scalar(@{$imports}) > 30 || scalar(@{$selectors}) > 4000;

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

