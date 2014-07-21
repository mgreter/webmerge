################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Plugin::JS::YUI;
################################################################################

use utf8;
use strict;
use warnings;

################################################################################
use IPC::Run3 qw(run3);
################################################################################

# plugin namespace
my $ns = 'js::yui';

################################################################################
# alter data in-place
################################################################################
use File::Spec::Functions qw(catfile);

################################################################################
# load file handling modules
################################################################################
use File::Temp qw(tempfile);
use File::Slurp qw(read_file);

################################################################################
# basic source map handling
################################################################################
use JSON qw(encode_json decode_json);

################################################################################
# main plugin function
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

	# temporary handle for source maps
	my ($fh, $filename) = tempfile();

	# create the command to execute the closure compiler
	my $command = '"' . $java_bin . '" -jar ' .
			# reference the closure compiler relative from extension
			'"' . $file->respath('{EXT}/vendor/yahoo/yui/yuicompressor.jar') . '"'
			# add option for source map creation (use temporary file)
			. sprintf(' --create_source_map "%s"  --source_map_format=%s', $filename, 'V3')
			# use simple and safe compilation options
			. ' --compilation_level SIMPLE_OPTIMIZATIONS'
			# use quiet warning level
			. ' --warning_level QUIET'
			# use safe line breaks
			. ' --line-break'
			# force utf8 charset
			. ' --charset UTF8'
			# force js type
			. ' --type js'
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

	# read generated source map
	# ToDo: need encoding for source map?
	my $srcmap = read_file($fh);
	# decode the json data to mangle
	my $json = decode_json($srcmap);
	# assertion that we were able to decode the json
	die "could not decode source map json\n" unless $json;
	# change the original filename on the source map
	$json->{'sources'}->[0] = 'closure-input.js';

	# check if there was any error while creating source maps
	die "closure compiler did not create source map\n\n" unless $srcmap;

	# return references
	return ($data, $json);

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