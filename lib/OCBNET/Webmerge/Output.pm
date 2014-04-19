################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Output;
################################################################################
use base OCBNET::Webmerge::IO::File;
################################################################################

use strict;
use warnings;

################################################################################
# no implementation yet
################################################################################

sub export { $_[0]->logFile('export') }
sub checksum { $_[0]->logFile('checksum') }

################################################################################
# process for output target
################################################################################
use Encode qw(encode);
################################################################################

sub postprocess
{

	# get node and data
	# alter original data
	my ($output, $data) = @_;

	# log action to console
	$output->logFile('process');

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
	push @parts, ${$_->content} foreach $parent->find('prefix');
	# add in order of their naming via includer
		push @parts, $_->render($output) foreach $parent->find('prepend');
	push @parts, $_->render($output) foreach $parent->find('input');
	push @parts, $_->render($output) foreach $parent->find('append');
	# always add suffix unaltered
	push @parts, ${$_->content} foreach $parent->find('suffix');
	push @parts, $output->suffix;

	# join the final data (filter undefined or empty parts)
	my $data = join(';', grep { defined $_ && $_ ne '' } @parts);

	# encode data into requested encoding
	$data = encode($output->{'encoding'}, $data);

	# return scalar ref
	return \ $data;

}

################################################################################
# implement on specific types and targets
################################################################################

sub prefix { }
sub suffix { }

################################################################################
################################################################################
1;