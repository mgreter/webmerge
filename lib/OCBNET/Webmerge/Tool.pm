################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Tool;
################################################################################

use strict;
use warnings;

################################################################################
# tools can be registered from outside
################################################################################

# store all tools
my @tools;

# register a new tool
sub register
{

	# get arguments
	my ($name, $fn, $prio) = @_;

	# create a new option for webmerge
	OCBNET::Webmerge::options($name, $name . '!', 1);

	# add variables to tools array
	push @tools, [$name, $fn, $prio];

}

################################################################################
# run all registered tools in order
################################################################################

sub run
{
	# run all tools that are enabled by settings
	foreach my $tool (sort { $a->[2] - $b->[2] } @tools)
	{ foreach (@_) { &{$tool->[1]}($_) if $_->setting($tool->[0]) } }
}

################################################################################
# load additional tools
################################################################################

use OCBNET::Webmerge::Tool::Execute;
use OCBNET::Webmerge::Tool::Checksum;
use OCBNET::Webmerge::Tool::Watchdog;
use OCBNET::Webmerge::Tool::Webserver;

################################################################################
################################################################################
1;
