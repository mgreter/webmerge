################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Output;
################################################################################
use base OCBNET::Webmerge::File;
################################################################################

use strict;
use warnings;

################################################################################
# no implementation yet
################################################################################

sub export { $_[0]->logAction('export') }
sub finalize { $_[0]->logAction('finalize') }

################################################################################
# create the checksum file
################################################################################

sub inputs
{

	# get arguments
	my ($output) = @_;

	# log action to console
	$output->logFile('render');

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
		$_ && $_->enabled &&
		# filter targets that do not match
		( $_->target && $_->target eq $target );
	};

	# clean all arrays and resolve all id references
	@input = grep $filter, map { $_->inputs } @input;
	@prefix = grep $filter, map { $_->inputs } @prefix;
	@suffix = grep $filter, map { $_->inputs } @suffix;

	# return as special array
	return [\@input, \@prefix, \@suffix];

}

################################################################################
# create the checksum file
################################################################################

sub checksum
{

	# get arguments
	my ($output, $data) = @_;

	# declare local variable to collect checksums
	my ($inputs, @md5sum, @inputs) = ($output->inputs);

	# process all input items fetched from output node
	foreach my $input (@{$inputs->[1]}, @{$inputs->[0]}, @{$inputs->[2]})
	{
		# get md5sum for input and append to sums
		push @md5sum, my $md5sum = $input->md5sum;
		# create checksum for every input file for final crc file
		push @inputs, join(': ', $input->localurl, $md5sum);
	}

	# create a hash
	my $md5_inputs = $output->md5sum(\join("::", @md5sum));

	# append the crc of all joined checksums
	${$data} .= "\n/* crc: " . $md5_inputs . " */\n"; # if $config->{'crc-comment'};

	# now calculate the output md5sum
	my $crc = $output->md5sum($data) . "\n\n";
	# add checksum over all inputs
	$crc .= $md5_inputs . "\n";
	# add list of crcs of all sources
	$crc .= join("\n", @inputs) . "\n";

	# create path to store checksum of this output
	my $checksum = OCBNET::Webmerge::CRC->new($output);

	$checksum->write(\$crc);

}

################################################################################
# implement for specific types and targets
################################################################################

sub prefix { }
sub suffix { }

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
	# return list with names
	return @processors;
}

################################################################################
# process for output target
################################################################################
use Encode qw(encode);
################################################################################

sub render
{

	# get arguments
	my ($output) = @_;

	# log action to console
	$output->logFile('render');

	# get list of all outputs
	my $parent = $output->parent;

	# get some options from attributes
	my $target = $output->target;

	# collect parts
	my @parts;

	# always add prefix unaltered
	push @parts, $output->prefix;
	push @parts, ${$_->contents} foreach $parent->find('prefix');
	# add in order of their naming via includer
	push @parts, $_->render($output) foreach $parent->find('prepend');
	push @parts, $_->render($output) foreach $parent->find('input');
	push @parts, $_->render($output) foreach $parent->find('append');
	# always add suffix unaltered
	push @parts, ${$_->contents} foreach $parent->find('suffix');
	push @parts, $output->suffix;

	# join the final data (filter undefined or empty parts)
	my $data = join("\n", grep { defined $_ && $_ ne '' } @parts) . "\n";

	# encode data into requested encoding
	$data = encode($output->encoding, $data);

	# return scalar ref
	return \ $data;

}

################################################################################
################################################################################
1;