################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Output;
################################################################################

use strict;
use warnings;

################################################################################
# some accessor methods
################################################################################

################################################################################
# render output context
################################################################################
use Encode qw(encode);
################################################################################


sub process
{

	# get node and data
	# alter original data
	my ($output, $data) = @_;

	# act upon different targets
	if ($output->target eq 'minify')
	{
		# minify via the perl cpan minifyer
		${$data} = $output->minify(${$data});
	}
	# compile has the best compression
	elsif ($output->target eq 'compile')
	{
		# compile via our own implementation
		${$data} = $output->compile(${$data});
	}

}

################################################################################

sub render
{

	# get arguments
	my ($output) = @_;

	# get list of all outputs
	my $parent = $output->parent;

	# get list of all input blocks
	my @prefix = $parent->find('prefix');
	my @prepend = $parent->find('prepend');
	my @input = $parent->find('input');
	my @append = $parent->find('append');
	my @suffix = $parent->find('suffix');

	# get some options from attributes
	my $target = $output->attr('target');

	# join sources
	my $data = "";

	# always add prefix unaltered
	$data .= ${$_->read} foreach @prefix;
	# add in order of their naming via includer
	$data .= $_->render($output) foreach @prepend;
	$data .= $_->render($output) foreach @input;
	$data .= $_->render($output) foreach @append;
	# always add suffix unaltered
	$data .= ${$_->read} foreach @suffix;

	# encode data into requested encoding
	$data = encode($output->{'encoding'}, $data);

	$output->process(\$data);


	# compile the output
	# post process output

	# return scalar ref
	return \ $data;

}



################################################################################
################################################################################
1;