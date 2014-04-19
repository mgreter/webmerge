################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Plugin::CSS::SASS;
################################################################################

use strict;
use warnings;

################################################################################

# plugin namespace
my $ns = 'css::sass';

################################################################################
# alter data in-place
################################################################################
use IPC::Run3 qw(run3);
################################################################################

sub process
{

	# get arguments
	my ($data, $file, $scope) = @_;

	# create the command to execute the closure compiler
	my $command = 'sass -s --scss';

	# I should only listen for my own children
	# IPC::Run3 will spawn it's own children
	local $SIG{CHLD} = undef;

	# force unix linefeeds
	${$data}=~s/\r\n/\n/g;
	# had issues with doubled lfs
	$command .= ' --unix-newlines';

	# make all absolute local paths relative to current directory
	# also changes urls in comments (needed for the spriteset feature)
	# ${$data} =~ s/$re_url/wrapURL(exportURI($+{url}, $directory))/egm;

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

	# change all uris to absolute paths (relative to local directory)
	# also changes urls in comments (needed for the spriteset feature)
	# this way, new urls inserted by sass processor will also be imported
	# $compiled =~ s/$re_url/wrapURL(importURI($+{url}, $directory, $config))/egm;

	# add an indicator about the processor (put compiled code)
	${$data} = "/* ruby sass root: url($file->dpath) */\n\n" . $compiled;

}

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