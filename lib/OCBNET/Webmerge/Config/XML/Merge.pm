################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Config::XML::Merge;
################################################################################
use base 'OCBNET::Webmerge::Config::XML::Scope';
################################################################################
require OCBNET::Webmerge::Config::XML::Merge::JS;
require OCBNET::Webmerge::Config::XML::Merge::CSS;
################################################################################

use strict;
use warnings;

################################################################################
# execute main action
################################################################################

sub execute
{
	# get arguments
	my ($node) = @_;
	# get list of all outputs
	my @output = $node->find('output');
	# get list of all input blocks
	my @suffix = $node->find('suffix');
	my @prepend = $node->find('prepend');
	my @input = $node->find('input');
	my @append = $node->find('append');
	my @prefix = $node->find('prefix');
	# process each output file
	foreach my $input (@input)
	{
		my $rv = $input->read;
		# print "read ", $rv, "\n";
	}

	foreach my $output (@output)
	{
		# print "write ", $output->path, "\n";
		$output->write($output->render)
	}
	# pass to my super class
	shift->SUPER::execute(@_);
}

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'MERGE' }

################################################################################
################################################################################
1;