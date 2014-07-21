################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Merge;
################################################################################

use strict;
use warnings;
use File::chdir;

################################################################################
use Cwd qw(getcwd);
################################################################################

sub execute
{

	# get input arguments
	my ($node, $context) = @_;

	# fetch the directory difference from actual working dir
	my $cd_in = OCBNET::Webmerge::dpath($node->workroot, '.');
	my $cd_out = OCBNET::Webmerge::dpath('.', $node->workroot);

	# abort the execution if merge is disabled
	return $node unless $node->setting('merge');

	# change directory
	if ($cd_in ne '.')
	{
		warn "chdir ", $cd_in, "\n";
		# try to actually change directory here
		local $CWD = $cd_in or die "chdir error: $!";
	}

	# execute prepare steps before any other thing
	$_->execute($context) foreach $node->find('PREPARE');

	# process all output targets in merge
	foreach my $output ($node->find('OUTPUT'))
	{
		# starting to generate output file
		warn "generating ", $output->dpath, "\n";
		# render the output data and source map
		my ($data, $srcmap) = $output->render;

		# die "no srcmap" unless $srcmap;
		# die "yoyo srcmap $srcmap $output" if $srcmap;

		# write to generate output file
		warn "   writing ", $output->dpath, "\n";
		# write the output data to disk
		my $rv = $output->write($data, $srcmap);
		# $rv &= $output->srcmap->write($srcmap);
		die "could not write data" unless $rv;
		# everything was successfully done
		warn " completed ", $output->dpath, "\n";
	}

	# execute finish steps after everything is done
	$_->execute($context) foreach $node->find('FINISH');

	# change directory
	if ($cd_out ne '.')
	{
		warn "chdir ", $cd_out, "\n";
		# try to actually change directory here
		local $CWD = $cd_out or die "chdir error: $!";
	}

}

################################################################################
use OCBNET::Webmerge qw(options);
################################################################################

options('merge', '!', 1);

################################################################################
################################################################################
1;
