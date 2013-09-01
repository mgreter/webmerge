###################################################################################################
package RTP::Webmerge::Compile::JS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Compile::JS::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(compileJS); }

###################################################################################################

# run3 to get stdout and stderr
use IPC::Run3 qw(run3);

# run3 to get stdout and stderr
use RTP::Webmerge::Path qw($extroot res_path);

###################################################################################################

sub compileJS
{

	# get input variables
	my ($content, $config) = @_;

	# make these configurable again
	my $java_bin = '/usr/bin/java';

	# hotfix for windows operating system
	# all windows (even x64) report MSWin32!
	$java_bin = "java" if ($^O eq "MSWin32");

	# create the command to execute the closure compiler
	my $command = $java_bin . ' -jar ' .
			# reference the closure compiler relative from extension
			res_path('{EXT}/scripts/closure-compiler/compiler.jar') .
		' --warning_level QUIET --compilation_level SIMPLE_OPTIMIZATIONS';

	# I should only listen for my own children
	# IPC::Run3 will spawn it's own children
	local $SIG{CHLD} = undef;

	# now call run3 to compile the javascript code
	my $rv = run3($command, \ $content, \ my $compiled, \ my $err);

	# check if there was any error given by closure compiler
	die "closure compiler had an error, aborting\n$err" if $err;

	# test if ipc run3 returned success
	die "closure compiler exited unexpectedly (code $?)" if $?;

	# test if ipc run3 returned success
	die "could not run closure compiler, aborting" if $rv != 1;

	# return compiled
	return $compiled;

}
# EO sub compileJS

###################################################################################################
###################################################################################################
1;
