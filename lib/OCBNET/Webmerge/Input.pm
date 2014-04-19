################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Input;
################################################################################
use base OCBNET::Webmerge::IO::File;
################################################################################

use strict;
use warnings;

################################################################################
# no implementation yet
################################################################################

sub import { $_[0]->logFile('import') }

################################################################################
# return the processed data
################################################################################

sub preprocess
{

	# get arguments
	my ($input, $output) = @_;

	# get the imported content
	my $data = $input->import;

	# do the processing now
	if ($input->attr('process'))
	{
		# split list of all processes
		my $process = $input->attr('process');
		# give a debug message about the action
		$input->logAction($input->attr('process'));
		# implement processing to alter the data
		foreach my $name (split /\s*\|\s*/, $process)
		{
			# alternative name built via scope tag name
			my $alt = $input->scope->tag . '::' . $name;
			# get the processor by name from the document
			my $processor = $input->document->processor($alt) ||
			                $input->document->processor($name);
			die "processor $name not found" unless $processor;
			# execute processor and pass data
			&{$processor}($data, $input, $output);
		}
	}
	# EO if attr process

$data }

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

	# otherwise read the input
	${$input->content};

}

################################################################################
################################################################################
1;