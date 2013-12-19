###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Process::SASS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Process::SASS::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(compileSASS); }

###################################################################################################

# run3 to get stdout and stderr
use IPC::Run3 qw(run3);

# run3 to get stdout and stderr
use RTP::Webmerge::Path qw(EOD $extroot check_path);

###################################################################################################

# compile js via ruby sass compiler
#**************************************************************************************************
sub sass
{

	# get input variables
	my ($data, $config, $output) = @_;

	# make these configurable again
	# my $java_bin = '/usr/bin/java';

	# hotfix for windows operating system
	# all windows (even x64) report MSWin32!
	# $java_bin = "java" if ($^O eq "MSWin32");

	# if java home is given we will force to use t
	# if (exists $ENV{'JAVA_HOME'} && defined $ENV{'JAVA_HOME'})
	# { $java_bin = join(EOD, $ENV{'JAVA_HOME'}, 'bin', 'java'); }

	# create the command to execute the closure compiler
	my $command = 'sass -s --scss';

	# I should only listen for my own children
	# IPC::Run3 will spawn it's own children
	local $SIG{CHLD} = undef;

	# now call run3 to compile the javascript code
	my $rv = run3($command, $data, \ my $compiled, \ my $err);

	# print content to console if we have errors
	# this should only ever print error messages
	print $compiled if $err || $? || $rv != 1;

	# check if there was any error given by closure compiler
	die "sass compiler had an error, aborting\n$err", "\n" if $err;

	# test if ipc run3 returned success
	die "sass compiler exited unexpectedly (code $?)", "\n" if $?;

	# test if ipc run3 returned success
	die "could not run sass compiler, aborting", "\n" if $rv != 1;

	# overwrite old data
	${$data} = $compiled;

	# return compiled
	return 1;

}
# EO sub compileSASS

###################################################################################################

# import registered processors
use RTP::Webmerge qw(%processors);

# register the processor function
$processors{'sass'} = \& sass;

###################################################################################################
###################################################################################################
1;