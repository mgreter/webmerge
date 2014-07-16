################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Runner;
################################################################################

use strict;
use warnings;

################################################################################
# runners can be registered from outside
################################################################################
use OCBNET::Webmerge qw(options);
################################################################################

# store all runners
our @runners;

# register a new runner
sub register
{

	# get arguments
	my ($opt, $fn, $prio, $default) = @_;

	# enable runners if default is null
	$default = 1 unless defined $default;

	# split getopt config string (option|o)
	my ($name, $short) = split /\|/, $opt, 2;

	# create additional option string for actual registration
	$opt = sprintf(defined $short ? "|%s!" : "%s!", $short || '');

	# create and register new option
	options($name, $opt, $default);

	# add variables to runners array
	push @runners, [$name, $fn, $prio, $default];

}

################################################################################
# run all registered runners in order
################################################################################
use List::MoreUtils qw(uniq);
################################################################################

sub run
{
	# run all runners that are enabled by settings
	foreach my $runner (sort { $a->[2] - $b->[2] } @runners)
	{ foreach (uniq @_) { &{$runner->[1]}($_) if $_->setting($runner->[0]) } }
}

################################################################################
# load additional runners
################################################################################

use OCBNET::Webmerge::Runner::Execute;
use OCBNET::Webmerge::Runner::Checksum;
use OCBNET::Webmerge::Runner::Watchdog;
use OCBNET::Webmerge::Runner::Webserver;

################################################################################
################################################################################
1;
