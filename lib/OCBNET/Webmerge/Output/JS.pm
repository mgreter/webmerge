################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Output::JS;
################################################################################
use base qw(
	OCBNET::Webmerge::Output
	OCBNET::Webmerge::IO::File::JS
);
################################################################################

use strict;
use warnings;

################################################################################
# run3 to get stdout and stderr
use IPC::Run3 qw(run3);
################################################################################

use constant EOD => "\\";

################################################################################
# compile js via google closure compiler
################################################################################

sub compile
{

	# get input variables
	my ($output, $content) = @_;

	# print debug message
	$output->logAction('compile');

	# make this configurable again
	my $java_bin = '/usr/bin/java';

	# hotfix for windows operating system
	# all windows (even x64) report MSWin32!
	$java_bin = "java" if ($^O eq "MSWin32");

	# if java home is given we will force to use it
	if (exists $ENV{'JAVA_HOME'} && defined $ENV{'JAVA_HOME'})
	{ $java_bin = join(EOD, $ENV{'JAVA_HOME'}, 'bin', 'java'); }

	# create the command to execute the closure compiler
	my $command = '"' . $java_bin . '" -jar ' .
			# reference the closure compiler relative from extension
			'"' . $output->respath('{EXT}/vendor/google/closure/compiler.jar') . '"' .
			# use quiet warning level and safe compilation options
			' --warning_level QUIET --compilation_level SIMPLE_OPTIMIZATIONS';

	# I should only listen for my own children
	# IPC::Run3 will spawn it's own children
	local $SIG{CHLD} = undef;

	# now call run3 to compile the javascript code
	my $rv = run3($command, \ $content, \ my $compiled, \ my $err);

	# print content to console if we have errors
	# this should only ever print error messages
	print $compiled if $err || $? || $rv != 1;

	# check if there was any error given by closure compiler
	die "closure compiler had an error, aborting\n$err", "\n" if $err;

	# test if ipc run3 returned success
	die "closure compiler exited unexpectedly (code $?)", "\n" if $?;

	# test if ipc run3 returned success
	die "could not run closure compiler, aborting", "\n" if $rv != 1;

	# return compiled
	return $compiled;

}
# EO sub compileJS

################################################################################

sub minify
{

	# get input variables
	my ($output, $content) = @_;

	# print debug message
	$output->logAction('minify');

	# module is optional
	require JavaScript::Minifier;

	# minify via the perl cpan minifyer
	JavaScript::Minifier::minify('input' => $content)

}

################################################################################
################################################################################
1;
















__DATA__



###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Compile::JS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Compile::JS::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(compileJS); }

###################################################################################################


# run3 to get stdout and stderr
use RTP::Webmerge::Path qw(EOD $extroot check_path);

###################################################################################################

###################################################################################################
###################################################################################################
1;
