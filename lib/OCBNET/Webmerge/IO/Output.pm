################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::Output;
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

sub prefix { }
sub suffix { }

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

# every input must also return a source map!
# use intermediate object to handle both contents

# my $merge = new OCBNET::IO::SMAP;
# $merge->add($content, $smap);
# $merge->add($_->contents);
# $merge->add($_->render($output));
# $merge->add($content, $smap);
# $merge->add($content, $smap);
use OCBNET::SourceMap::V3;
my $smap = OCBNET::SourceMap::V3->new;

#die $smap;


my @files =
		# only usefull strings
		grep { ! ${$_->[0]} =~ m/^\s*$/ }
		# only defined strings
		grep { defined ${$_->[0]} }
		# only defined scalars
		grep { defined $_->[0] }

( # collect a list of scalars
#		( [ \ $output->prefix ] ),
#		(map { [ $_->contents ] } @{$inputs[1]}),
		(map { [ $_->render($output) ] } @{$inputs[0]}),
#		(map { [ $_->contents ] } @{$inputs[2]}),
#		( [ \ $output->suffix ] )
);


#die $files[0]->[1];

#die $inputs[0]->[0]->render($output);

my $data = '';

foreach (@files)
{
	die "missing source map" unless defined $_->[1];

use Data::Dumper;

# also need to mixin to smap!!

my @dmp = @{$_->[1]->{'mappings'}};
@dmp = grep { $_ && scalar(@{$_}) } @dmp;
#warn Data::Dumper::Dumper (\@dmp);
#warn "X" x 80, "\n";

my $nl = [];


push @{$nl}, pop @{$_->[1]->{'mappings'}->[-1]};

$nl->[0]->[0] = 0;
$nl->[0]->[2] ++;

push @{$_->[1]->{'mappings'}}, $nl;

	$smap->add($_->[0], $_->[1]);

	$data .= ${$_->[0]} . "\n";

@dmp = @{$_->[1]->{'mappings'}};
@dmp = grep { $_ && scalar(@{$_}) } @dmp;
#warn Data::Dumper::Dumper (\@dmp);
#warn "X" x 80, "\n";

	my $lcnt = $data =~ tr/\n/\n/;
	my $mcnt = $#{$smap->{'mappings'}};
	die "$lcnt $mcnt" if $mcnt ne $lcnt;

}

;

#my $data = join("",
		# unwrap references
#		map { ${$_->[0]} }

#@files);

	my $lcnt = $data =~ tr/\n/\n/;
	my $mcnt = $#{$smap->{'mappings'}};
	die "$lcnt $mcnt" if $mcnt ne $lcnt;

$smap->{'new'} = 1;

	return (\ $data, $smap);

}

################################################################################
# create the checksum file
################################################################################
# require OCBNET::Webmerge::CRC;
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
		# import the file
		$input->contents;
		# get further dependencies (aka css imports)
		foreach my $file ($input, $input->collect('file'))
		{
			# get md5sum for input and append to sums
			push @md5sum, my $md5sum = $file->{'crc'};
			# create checksum for every input file for final crc file
			push @inputs, join(': ', $file->localurl($output->dirname), $md5sum);
		}
	}

	# create an md5 out of all joined input md5s
	my $md5_inputs = $output->md5sum(\join("::", @md5sum));

	# append the crc of all joined checksums
	${$data} .= "\n/* crc: " . $md5_inputs . " */\n"; # if $config->{'crc-comment'};

	# now calculate the output md5sum (have raw data)
	my $crc = $output->md5sum($data) . "\n\n";
	# add checksum over all inputs
	$crc .= $md5_inputs . "\n";
	# add list of crcs of all sources
	$crc .= join("\n", @inputs) . "\n";
require OCBNET::Webmerge::IO::CRC;
	# create path to store checksum of this output
	my $checksum = OCBNET::Webmerge::IO::CRC->new($output);

	# finally write the crc
	$checksum->write(\$crc);

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
