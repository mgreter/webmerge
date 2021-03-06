################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Plugin::CSS::SCSS;
################################################################################

use strict;
use warnings;
use File::chdir;

################################################################################

# plugin namespace
my $ns = 'css::scss';

################################################################################
# alter data in-place
################################################################################
my $footer = "/* libsass base: url(%s) */\n\n";
################################################################################

sub process
{

	# get arguments
	my ($file, $data) = @_;

	# load the cscc compiler
	require CSS::Sass;

	# init scss compiler object
	my $scss = CSS::Sass->new(

		# TODO: add current path from config step
		# include_paths => ['some/include/path'],

		# always output in nice formated way
		# will compress later by our own compilers
		output_style => CSS::Sass::SASS_STYLE_NESTED(),

		# needed for watchdog (fork?)
		# include_paths   => [ cwd ],

		# output debug comments
		# source_comments => $config->{'debug'},

		# dont die on errors
		# handle them myself
		dont_die => 1

	);
	# init scss object

	# make all absolute local paths relative to current directory
	# also changes urls in comments (needed for the spriteset feature)
	# ${$data} =~ s/$re_url/wrapURL(exportURI($+{url}, $directory))/egm;

	local $CWD = $file->workroot;

	# compile the passed scss data
	${$data} = $scss->compile(${$data});

	# check if compile was ok
	unless (defined ${$data})
	{
		# output an error message (it may not tell much)
		die "Fatal error when compiling scss:\n",
		    join("\n", split('error:', $scss->last_error)),
		    "cwd: ", $file->workroot, "\n",
		    "path: ", $file->path, "\n";
	}

	# change all uris to absolute paths (relative to local directory)
	# also changes urls in comments (needed for the spriteset feature)
	# this way, new urls inserted by sass processor will also be imported
	# ${$data} =~ s/$re_url/wrapURL(importURI($+{url}, $directory, $config))/egm;

	# add an indicator about the processor
	${$data} = sprintf($footer, $file->path ) . ${$data};

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