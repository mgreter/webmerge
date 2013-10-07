###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Process::CSS::SCSS;
###################################################################################################

use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Process::CSS::SCSS::VERSION = "0.9.0" }

###################################################################################################

# process spritesets with additional modules
# try to keep them as standalone as possible
sub scss
{

	# load the cscc compiler
	require CSS::Sass;

	# get input variables
	my ($data, $config, $output) = @_;

	# init scss compiler object
	my $scss = CSS::Sass->new(

		# TODO: add current path from config step
		# include_paths => ['some/include/path'],

		# always output in nice formated way
		# will compress later by our own compilers
		output_style => CSS::Sass::SASS_STYLE_NESTED(),

		# output debug comments
		source_comments => $config->{'debug'},

		# dont die on errors
		# handle them myself
		dont_die => 1

	);
	# init scss object

	# compile the passed scss data
	${$data} = $scss->compile(${$data});

	# check if compile was ok
	unless (defined ${$data})
	{
		# output an error message (it may not tell much)
		die "Fatal error when compiling scss:\n",
		    " in ", $output->{'path'}, "\n", $scss->last_error;
	}

	# return success
	return 1;

}
# EO sub scss

###################################################################################################

# import registered processors
use RTP::Webmerge qw(%processors);

# register the processor function
$processors{'scss'} = \& scss;

###################################################################################################
###################################################################################################
1;