################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Merge::JS;
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
	# $node->log("execute MERGE::JS");
	foreach my $output ($node->find('OUTPUT'))
	{
		STDOUT->autoflush(1);
		$node->logAction('render');
		my $data = $output->render;
		$node->logAction('write');
		my $rv = $output->write($data);
		$node->logSuccess($rv);
	}
}

# sub execute
# {
# 	my ($node, $context) = @_;
# }

################################################################################
# some accessor methods
################################################################################

# return node type
sub type { 'INPUT::JS' }

################################################################################
################################################################################
1;