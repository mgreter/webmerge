################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Merge::CSS;
################################################################################
# use base 'OCBNET::Webmerge::Merge';
################################################################################

use strict;
use warnings;

################################################################################
# execute main action
################################################################################

sub execute
{
	my ($node, $context) = @_;
	die "jo";
}

sub merge
{
	my ($node, $context) = @_;

my $encoding = 'ISO-8859-1';

$encoding = 'utf8';

	foreach my $out ($node->find('OUTPUT'))
	{
		die $out;
	}

open(my $fh, ">>:encoding($encoding)", "d:\\output.txt");

	print $fh "\@charset \"$encoding\";\n\n" if ($encoding ne "utf8");
	foreach my $in ($node->find('INPUT'))
	{
		my $css = $in->read;
		print $fh ${$css}, "\n";
	}

	return "merge css";
}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT::CSS' }

################################################################################
################################################################################
1;