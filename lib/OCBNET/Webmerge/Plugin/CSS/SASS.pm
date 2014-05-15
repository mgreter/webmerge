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
my $header = "/* ruby sass base: url(%s) */\n\n";
################################################################################

sub process
{

	# get arguments
	my ($file, $data) = @_;

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

	# set encoding options
	my $options = {
		'binmode_stdin' => ':encoding(utf8)',
		'binmode_stdout' => ':encoding(utf8)',
		'binmode_stderr' => ':encoding(utf8)'
	};

	# now call run3 to compile the javascript code
	my $rv = run3($command, $data, \ my $compiled, \ my $err, $options);

	# fix input output handles
	OCBNET::Webmerge::fixIOenc;

	# print content to console if we have errors
	# this should only ever print error messages
	print $compiled if $err || $? || $rv != 1;

	# check if we have an error on some line
	# this is not optimal, but it is usefull
	# if it works (better than nothing at all)
	if ($err)
	{
		# normalize the error message a little
		$err =~ s/\: expected/\:\nexpected/g;
		# add main error message to the final result
		# maybe add a more elaborate error handling later
		chomp $err; my @errors = (lcfirst $err);
		# add a generic error header to explain it better
		unshift @errors, 'sass compiler reported an error';
		# check if we have a code location
		if($err =~ m/line\s+(\d+)/)
		{
			# split existing code into lines
			my @lines = split /\n/, ${$data};
			# extract the lines that are interesting
			for (my $i = $1 - 7; $i < $1 + 3; $i++)
			{
				my $line = substr $lines[$i - 1], 0, 60;
				push @errors, sprintf "%s | %s", $i, $line;
			}
		}
		# throw actual errors
		die join "\n", @errors, "\n";
	}

	# test if ipc run3 returned success
	die "sass compiler exited unexpectedly (code $?)", "\n" if $?;

	# test if ipc run3 returned success
	die "could not run sass compiler, aborting", "\n" if $rv != 1;

	# change all uris to absolute paths (relative to local directory)
	# also changes urls in comments (needed for the spriteset feature)
	# this way, new urls inserted by sass processor will also be imported
	# $compiled =~ s/$re_url/wrapURL(importURI($+{url}, $directory, $config))/egm;

	# add an indicator about the processor (put compiled code)
	${$data} = sprintf($header, $file->path) . $compiled;

	# return reference
	return \ $compiled;

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