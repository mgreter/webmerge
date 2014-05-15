################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Plugin::JS::Compile;
################################################################################

use utf8;
use strict;
use warnings;

################################################################################
use IPC::Run3 qw(run3);
################################################################################

# plugin namespace
my $ns = 'js::compile';

################################################################################
# alter data in-place
################################################################################
use File::Spec::Functions qw(catfile);
################################################################################

sub process
{

	# get arguments
	my ($file, $data) = @_;

	# make these configurable again
	my $java_bin = '/usr/bin/java';

	# hotfix for windows operating system
	# all windows (even x64) report MSWin32!
	$java_bin = "java" if ($^O eq "MSWin32");

	# if java home is given we will force to use t
	if (exists $ENV{'JAVA_HOME'} && defined $ENV{'JAVA_HOME'})
	{ $java_bin = catfile($ENV{'JAVA_HOME'}, 'bin', 'java'); }

	# create the command to execute the closure compiler
	my $command = '"' . $java_bin . '" -jar ' .
			# reference the closure compiler relative from extension
			'"' . $file->respath('{EXT}/vendor/google/closure/compiler.jar') . '"'
			# use simple and safe compilation options
			. ' --compilation_level SIMPLE_OPTIMIZATIONS'
			# use quiet warning level
			. ' --warning_level QUIET'
			# force utf8 charset
			. ' --charset UTF8'
	;

	# I should only listen for my own children
	# IPC::Run3 will spawn it's own children
	local $SIG{INT} = sub {};
	local $SIG{CHLD} = sub {};

	# set encoding options
	my $options = {
		'binmode_stdin' => ':encoding(utf8)',
		'binmode_stdout' => ':encoding(utf8)',
		'binmode_stderr' => ':encoding(utf8)',
	};

	# now call run3 to compile the javascript code
	my $rv = run3($command, $data, $data, \ my $err, $options);

	# fix input output handles
	OCBNET::Webmerge::fixIOenc;

	# print content to console if we have errors
	# this should only ever print error messages
	print ${$data} if $err || $? || $rv != 1;

	# check if there was any error given by closure compiler
	die "closure compiler had an error, aborting\n$err", "\n" if $err;

	# test if ipc run3 returned success
	die "closure compiler exited unexpectedly (code $?)", "\n" if $?;

	# test if ipc run3 returned success
	die "could not run closure compiler, aborting", "\n" if $rv != 1;

	# return reference
	return $data;

}
# EO process

################################################################################
# called via perl loaded
################################################################################

sub import
{
	# get arguments
	my ($fqns, $node, $webmerge) = @_;
	# register our processor to document
	$node->document->processor($ns, \&process);
}

################################################################################
################################################################################
1;