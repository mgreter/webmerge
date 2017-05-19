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
use IPC::Run3 qw(run3);

# run3 to get stdout and stderr
use RTP::Webmerge::Path qw(EOD $extroot check_path);

###################################################################################################

# compile js via google closure compiler
#**************************************************************************************************
sub compileJS
{

	# get input variables
	my ($content, $config) = @_;

	# make these configurable again
	my $java_bin = '/usr/bin/java';

	# hotfix for windows operating system
	# all windows (even x64) report MSWin32!
	$java_bin = "java" if ($^O eq "MSWin32");

	# if java home is given we will force to use t
	if (exists $ENV{'JAVA_HOME'} && defined $ENV{'JAVA_HOME'})
	{ $java_bin = join(EOD, $ENV{'JAVA_HOME'}, 'bin', 'java'); }

	# create the command to execute the closure compiler
	# -Xss512M failed in one instance with jre 1.8.0_131-b11
	my $command = '"' . $java_bin . '" -jar ' .
			# reference the closure compiler relative from extension
			'"' . check_path('{EXT}/scripts/google/closure/compiler.jar') . '"' .
			# use es5 output level (more permisive)
			" --language_in=ES5_STRICT --language_out=ES5" .
			# use quiet warning level and safe compilation options
			' --warning_level QUIET --compilation_level SIMPLE_OPTIMIZATIONS';
			# ' --warning_level QUIET --compilation_level WHITESPACE_ONLY';

	# I should only listen for my own children
	# IPC::Run3 will spawn it's own children
	local $SIG{CHLD} = undef;

	# now call run3 to compile the javascript code
	my $rv = run3($command, \ $content, \ my $compiled, \ my $err);

	# newer closure compiler emits this on stdout if fed via stdin
	# see https://github.com/google/closure-compiler/issues/1315
	$err =~ s/The compiler is waiting for input via stdin.\r?\n//;

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

###################################################################################################
###################################################################################################
1;
