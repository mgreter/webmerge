################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Mixin::Process;
################################################################################

use strict;
use warnings;

################################################################################
# list all processors for this file
################################################################################

sub processors {

	split (/(?:\s*\|\s*|\s+)/, $_[0]->attr('postprocess') || ''),
	split (/(?:\s*\|\s*|\s+)/, $_[0]->attr('process') || ''),
	split (/(?:\s*\|\s*|\s+)/, $_[0]->attr('preprocess') || ''),
}

################################################################################
# process the data/content and return result
################################################################################

sub process
{

	# get arguments
	my ($file, $data, $oldmap) = @_;

	# get data from file if not passed
	$data = $file->contents unless $data;

	# implement processing to alter the data
	foreach my $name ($file->processors)
	{
		# alternative name built via scope tag name
		my $alt = $file->scope->tag . '::' . $name;
		# get the processor by name from the document
		my $processor = $file->document->processor($alt) ||
		                $file->document->processor($name);
		# check if the processor name is valid
		# maybe you forgot to load some plugins
		die "processor $alt not found" unless $processor;
		# change working directory
		chdir $file->workroot;
		# execute processor and pass data
		# processor may returns a source map
		# can already be decoded from json or scalar
		my ($data, $jsmap) = &{$processor}($file, $data);
		# check if processor returned with success
		die "processor $name had an error" unless $data;
		# do the remapping if data is available
		if (defined $jsmap && defined $oldmap)
		{
			# create a new sourcemap object
			my $newmap = OCBNET::SourceMap->new;
			# read new mappings
			$newmap->read($jsmap);
			# remap to old mappings
			$newmap->remap($oldmap);
			# need to alter old hash
			%{$oldmap} = %{$newmap};
		}
	}
	# EO foreach processor name

	# return reference
	return ($data, $oldmap);

}
# EO process

################################################################################
################################################################################
1;

