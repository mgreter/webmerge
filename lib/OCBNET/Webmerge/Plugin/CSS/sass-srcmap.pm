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
	my $command = 'sass ';

	# I should only listen for my own children
	# IPC::Run3 will spawn it's own children
	local $SIG{CHLD} = undef;

	use RTP::Webmerge::IO::CSS qw(wrapURL);
	use RTP::Webmerge::Path qw(exportURI importURI $directory);

	# parse different string types
	our $re_apo = qr/(?:[^\'\\]+|\\.)*/s;
	our $re_quot = qr/(?:[^\"\\]+|\\.)*/s;

	our $re_url = qr/url\(\s*(?:
		\s*\"(?!data:)(?<url>$re_quot)\" |
		\s*\'(?!data:)(?<url>$re_apo)\' |
		(?![\"\'])\s*(?!data:)(?<url>[^\)]*)
	)\s*\)/xi;



	# force unix linefeeds
	${$data}=~s/\r\n/\n/g;
	# had issues with doubled lfs
	$command .= ' --unix-newlines --sourcemap';

	# make all absolute local paths relative to current directory
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(exportURI($+{url}, $directory))/egm;

	use File::Temp qw(); use Cwd qw(getcwd);
	use File::Slurp qw(write_file read_file);

	# create temporary files for the input and output
	# otherwise we will not be able to get the source map from sass
	my $out = File::Temp->new(DIR => getcwd, UNLINK => 0, SUFFIX  => '.css');
	my $in = File::Temp->new(DIR => getcwd, UNLINK => 0, SUFFIX  => '.scss');

	# prepare the input file for sass
	write_file( $in, {binmode => ':raw'}, ${$data} );

	# add input and output file to the final sass command
	$command .= sprintf(" %s:%s", $in->filename, $out->filename);

	# now call run3 to compile the javascript code
	# use undef to indicate that we have nothing on stdin
	my $rv = run3($command, undef, \ my $compiled, \ my $err);

	# now read the results the sass compiler has written
	$compiled = read_file ( $out, { binmode => ':raw' } );
	my $srcmap = read_file ( $out . '.map', { binmode => ':raw' } );
die $srcmap;
	# print content to console if we have errors
	# this should only ever print error messages
	print $compiled if $? || $rv != 1;

	# check if there was any error given by closure compiler
	warn "sass compiler had warning(s)\n$err", "\n" if $err;

	# test if ipc run3 returned success
	die "sass compiler exited unexpectedly (code $?)", "\n" if $?;

	# test if ipc run3 returned success
	die "could not run sass compiler, aborting", "\n" if $rv != 1;

	# change all uris to absolute paths (relative to local directory)
	# also changes urls in comments (needed for the spriteset feature)
	# this way, new urls inserted by sass processor will also be imported
	$compiled =~ s/$re_url/wrapURL(importURI($+{url}, $directory, $config))/egm;

	# add an indicator about the processor (put compiled code)
	${$data} = "/* ruby sass root: url($directory) */\n\n" . $compiled;

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