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
sub checksum { $_[0]->logAction('checksum') }
sub finalize { $_[0]->logAction('finalize') }

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
	push @parts, ${$_->content} foreach $parent->find('prefix');
	# add in order of their naming via includer
	push @parts, $_->render($output) foreach $parent->find('prepend');
	push @parts, $_->render($output) foreach $parent->find('input');
	push @parts, $_->render($output) foreach $parent->find('append');
	# always add suffix unaltered
	push @parts, ${$_->content} foreach $parent->find('suffix');
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