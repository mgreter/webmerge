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

use Cwd qw(cwd);

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

		# needed for watchdog (fork?)
		include_paths   => [ cwd ],

		# output debug comments
		source_comments => $config->{'debug'},

		# dont die on errors
		# handle them myself
		dont_die => 1

	);
	# init scss object

	# import local webroot path
	# import base filename functions
	use RTP::Webmerge::Path qw(dirname basename);
	use RTP::Webmerge::IO::CSS qw(wrapURL);
	use RTP::Webmerge::Path qw(exportURI importURI $directory);
	# parse urls out of the css file
	# do a lousy match for better performance
	our $re_url = qr/url\(\s*[\"\']?((?!data:)[^\)]+?)[\"\']?\s*\)/x;
	# change all web uris in the stylesheet to absolute local paths
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(importURI($1, $directory, $config))/egm;
	${$data} =~ s/$re_url/wrapURL(exportURI($1, cwd))/egm;

	# compile the passed scss data
	${$data} = $scss->compile(${$data});

	# resolve all local paths in the stylesheet to web uris
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(importURI($1, cwd, $config))/egm;

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