################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::File::Output;
################################################################################
use base qw(OCBNET::Webmerge::IO::File);
################################################################################
	use lib 'D:\github\OCBNET-SourceMap\lib';

use strict;
use warnings;

################################################################################
# load additional modules
################################################################################

# require OCBNET::Webmerge::Output::JS;
# require OCBNET::Webmerge::Output::CSS;
# require OCBNET::Webmerge::Output::HTML;
# require OCBNET::Webmerge::Output::ANY;

################################################################################
# implement for specific types and targets
################################################################################

sub prefix { warn "prefix called" }
sub suffix { warn "suffix called" }

################################################################################
# some common attribute getters
################################################################################

sub target { $_[0]->attr('target') || 'join' }

################################################################################
# get array with all input sources
################################################################################

sub inputs
{

	# get arguments
	my ($output) = @_;

	# get list of all outputs
	my $parent = $output->parent;

	# get some options from attributes
	my $target = $output->target;

	# declare local variables
	my (@prefix, @input, @suffix);
	# get all input sources
	push @input, $parent->find('prepend');
	push @input, $parent->find('input');
	push @input, $parent->find('append');
	# get the prefix and suffix sources
	push @prefix, $parent->find('prefix');
	push @suffix, $parent->find('suffix');

	# define filter
	my $filter = sub
	{
		# filter invalid and disabled
		($_ && $_->enabled) &&
		# filter targets that do not match
		( $_->target && $_->target eq $target );
	};

	# clean all arrays and resolve all id references
	@input = grep $filter, map { $_->files } @input;
	@prefix = grep $filter, map { $_->files } @prefix;
	@suffix = grep $filter, map { $_->files } @suffix;

	# return as special array
	return [\@input, \@prefix, \@suffix];

}

################################################################################
# process for output target
################################################################################
use OCBNET::SourceMap::V3;
################################################################################

sub render
{

	# get arguments
	my ($output) = @_;

	# start the source map mayhem

	# get list of all outputs
	my $parent = $output->parent;

	# get inputs via collector
	my @inputs = @{$output->inputs};

	# get some options from attributes
	my $target = $output->target;

	# create sourcemap for rendered output
	my $smap = OCBNET::SourceMap::V3->new;

	# every input must also return a source map!
	# use intermediate object to handle both contents
	my @files =
		# only usefull strings
		grep { ! ${$_->[0]} =~ m/^\s*$/ }
		# only defined strings
		grep { defined ${$_->[0]} }

		grep { ref $_->[0] ? 1 : warn "ADSQWREASDADSADS" }
		# only defined scalars
		grep { defined $_->[0] }
	( # collect a list of scalars
		( [ \ $output->prefix ] ),
		(map { [ $_->contents($output) ] } @{$inputs[1]}),
		(map { [ $_->render($output) ] } @{$inputs[0]}),
		(map { [ $_->contents($output) ] } @{$inputs[2]}),
		( [ \ $output->suffix ] )
	);

	my $merged = '';

	foreach my $file (@files)
	{

		unless (defined $file->[1])
		{
			use OCBNET::SourceMap::Utils qw(tokenize);
			$file->[1] = bless tokenize($file->[0]),
			                   "OCBNET::SourceMap::V3";
		}

		# check if file struct has a source map defined
		die "missing source map" unless defined $file->[1];

		# add content to data
		$merged .= ${$file->[0]};
		# add sourcemap to current sourcemap
		$smap->add($file->[0], $file->[1]);

		# assertion for equal length
		my $lcnt = $merged =~ tr/\n/\n/;
		my $mcnt = $#{$smap->{'mappings'}};
		die "assert: $lcnt $mcnt" if $mcnt ne $lcnt;

	}

	# assertion for equal length
	my $lcnt = $merged =~ tr/\n/\n/;
	my $mcnt = $#{$smap->{'mappings'}};
	die "assert: $lcnt $mcnt" if $mcnt ne $lcnt;

	$smap->{'new'} = 1;

	return (\ $merged, $smap);

}

################################################################################
# check agains saved checksum
################################################################################
use File::Spec::Functions qw(catfile);
################################################################################

sub check
{

	# get arguments
	my ($output, $crc) = @_;

#	delete $output->{'loaded'};
#	delete $output->{'readed'};
#	delete $output->{'written'};

	# split checksum file content into lines
	my @crcs = split(/\s*(?:\r?\n)+\s*/, ${$crc});

	# remove leading checksums
	my $checksum_result = shift(@crcs);
	my $checksum_joined = shift(@crcs);
#$output->contents;
#chop $output->{'loaded'};


	# check if the generated content changed
	if ($output->crc ne $checksum_result)
	{
		printf "FAIL - dst: %s\n", substr($output->path, - 45);
		printf "=> expect: %s\n", $checksum_result;
		printf "=> gotten: %s\n", $output->crc;
	}
	else
	{
		printf "PASS - dst: %s\n", substr($output->path, - 45);
	}

	# declare local variable
	my @md5sums;

	# process all source files
	foreach my $source (@crcs)
	{

		# split the line into path and checksum
		my ($path, $checksum) = split(/:\s*/, $source, 2);

my $crc; my $foo; my $bar;

		if ($path =~ s/^\>//)
		{
			my $input = $output->parent->query($path);
			$foo = $input->path; $crc = $input->crc;
			$bar = 'inline';
		}
		elsif ($path ne "")
		{
			# print "=== $source \n";
			# path is always relative to the checksum
			$path = catfile($output->dirname, $path);

			# load the css file with the given path name
			my $input = OCBNET::Webmerge::IO::File->new;
			# set the path on the attribute
			$input->{'attr'}->{'path'} = $path;
			# loosely couple the nodes together
			$input->{'parent'} = $output;

			$foo = $input->path;
			$crc = $input->crc;
			$bar = 'path';
		}
		else
		{
			die "assert";
		}


		push @md5sums, $crc;

		# check against stored value
		if ($crc ne $checksum)
		{
			printf "  FAIL - %s: %s\n", $bar, substr($foo, - 45);
			printf "  => expect: %s\n", $checksum;
			printf "  => gotten: %s\n", $crc;
		}
		else
		{
			printf "  PASS - %s: %s\n", $bar, substr($foo, - 45);
		}

	}

	if ($output->md5sum(\join('::', @md5sums)) ne $checksum_joined)
	{
		printf "FAIL - all: %s\n", substr($output->path, - 45);
	}
	else
	{
		printf "PASS - all: %s\n", substr($output->path, - 45);
	}

}

################################################################################
# extend processors list for targets
################################################################################

sub processors
{
	# get processors from attributes
	my @processors = $_[0]->SUPER::processors;
	# add more processors for certain targets
	push @processors, 'minify' if $_[0]->target eq 'minify';
	push @processors, 'compile' if $_[0]->target eq 'compile';
	# push @processors, 'license' if $_[0]->target eq 'license';
	# return list with names
	return @processors;
}

################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'OUTPUT' }

################################################################################
################################################################################
1;
