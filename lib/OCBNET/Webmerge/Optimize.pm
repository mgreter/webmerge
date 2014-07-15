################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
# Optimizers work on files and not on data stream. They replace the file
# inplace and have therefore be executed before or after other merge steps.
# It is used to optimize images and/or text files (html/css/js), but it is
# also used by the spriteset generator (which optimizes the resulting png).
################################################################################
package OCBNET::Webmerge::Optimize;
################################################################################
use base 'OCBNET::Webmerge::Tree::Node';
################################################################################

use strict;
use warnings;

################################################################################
# try to get number of cores
################################################################################

my $jobs; eval
{
	if ($^O eq 'MSWin32')
	{
		# try to get number of processors via cmd tool
		my $cores = `wmic cpu get NumberOfLogicalProcessors`;
		# remove expected leading text from output
		$cores =~ s/^NumberOfLogicalProcessors?\s*//;
		# declare jobs if we found expected result
		$jobs = $1 + 1 if $cores =~ m/^([0-9]+)\W/;
		# try again if not successfull
		unless (defined $jobs)
		{
			# try to get number of cores via cmd tool
			my $cores = `wmic cpu get NumberOfCores`;
			# remove expected leading text from output
			$cores =~ s/^NumberOfCores?\s*//;
			# declare jobs if we found expected result
			$jobs = $1 + 1 if $cores =~ m/^([0-9]+)\W/;
		}
	}
};

# otherwise use default
$jobs = 2 unless $jobs;

################################################################################
use OCBNET::Webmerge qw(options);
################################################################################

options('jobs', '|j=i', $jobs);
options('level', '|lvl=f', 2);
options('optimize', '|o!', -1);

################################################################################

sub execute
{
	# check if the option is enabled
	return unless $_[0]->setting('optimize');
	# go on with the execution
	shift->SUPER::execute(@_);
}

################################################################################
# load additional modules
################################################################################

require OCBNET::Webmerge::Optimize::ANY;
require OCBNET::Webmerge::Optimize::GIF;
require OCBNET::Webmerge::Optimize::PNG;
require OCBNET::Webmerge::Optimize::ZIP;
require OCBNET::Webmerge::Optimize::MNG;
require OCBNET::Webmerge::Optimize::JPG;
require OCBNET::Webmerge::Optimize::GZ;

################################################################################
################################################################################
1;
