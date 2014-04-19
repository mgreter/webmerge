################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::File;
################################################################################
use base OCBNET::Webmerge::IO::File;
################################################################################

use strict;
use warnings;

################################################################################
# list all processors for this file
################################################################################

sub processors { split /\s*\|\s*/, $_[0]->attr('process') || '' }

################################################################################
# process passed data or node content
################################################################################

sub process
{

	# get arguments
	my ($file, $data) = @_;

	# get data from file if not passed
	$data = $file->contents unless $data;

	# implement processing to alter the data
	foreach my $name ($file->processors)
	{
		# give a debug message
		$file->logAction($name);
		# alternative name built via scope tag name
		my $alt = $file->scope->tag . '::' . $name;
		# get the processor by name from the document
		my $processor = $file->document->processor($alt) ||
		                $file->document->processor($name);
		# check if the processor name is valid
		# maybe you forgot to load some plugins
		die "processor $name not found" unless $processor;
		# execute processor and pass data
		$data = &{$processor}($file, $data);
		# check if processor returned with success
		die "processor $name had an error" unless $data;
	}
	# EO foreach processor name

	# return reference
	return $data;

}
# EO process

################################################################################
use OCBNET::CSS3::URI qw(exportUrl);
################################################################################

# return (absolute) url to current webroot or given base
# if relative or absolute depends on the current config
# ******************************************************************************
sub weburl
{

	# get arguments
	my ($file, $abs, $base) = @_;

	# use webroot if no specific based passed
	$base = $file->webroot unless defined $base;

	# allow to overwrite this flag
	$abs = 1 unless defined $abs;

	# call function with correct arguments
	return exportUrl($file->path, $base, $abs);

}

# return (relative) url current directory or given base
# if relative or absolute depends on the current config
# ******************************************************************************
sub localurl
{

	# get arguments
	my ($file, $abs, $base) = @_;

	# use webroot if no specific based passed
	$base = $file->directory unless defined $base;

	# allow to overwrite this flag
	$abs = 0 unless defined $abs;

	# call function with correct arguments
	return exportUrl($file->path, $base, $abs);

}

################################################################################
################################################################################
1;

