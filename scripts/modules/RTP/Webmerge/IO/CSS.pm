###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::IO::CSS;
###################################################################################################
# http://www.w3.org/TR/CSS21/syndata.html#uri
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# parse urls out of the css file
# do a lousy match for better performance
our $re_url = qr/url\(\s*[\"\']?((?!data:)[^\)]+?)[\"\']?\s*\)/x;

# parse different string types
our $re_apo = qr/(?:[^\'\\]+|\\.)*/s;
our $re_quot = qr/(?:[^\"\\]+|\\.)*/s;

###################################################################################################

# parse imports with a strict match
# use same pattern as found in libsass
our $re_import = qr/
                   (?:url\(\s*(?:
                                  \'($re_apo+)\' |
                                  \"($re_quot+)\"
                                  |(?!data:)([^\)]+)
                            )\s*\)|
                            \'($re_apo+)\'|
                            \"($re_quot+)\"
                    )
                    (?:\s|\n|;)*
/x;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::IO::CSS::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our variables to be exported
BEGIN { our @EXPORT = qw(incCSS readCSS importCSS exportCSS writeCSS); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw($re_url wrapURL); }

###################################################################################################

# import webmerge io file reader and writer
use RTP::Webmerge::IO qw(readfile writefile);

# import local webroot path
use RTP::Webmerge::Path qw(exportURI importURI);

# import base filename functions
use RTP::Webmerge::Path qw(dirname basename);

###################################################################################################

# wrap url for css
# also makes it canonical
sub wrapURL
{

	# get uri
	my ($uri) = @_;

	# escape apostrophes
	$uri =~ s/\'/\\\'/g;

	# replace windows backslashes
	# with correct forward slashes
	$uri =~ s/\\/\//g if $^O eq "MSWin32";

	# wrap and return escaped uri
	return sprintf('url(\'%s\')', $uri);

}
# EO wrapURL

###################################################################################################


###################################################################################################

# include a css file
# resolve import statements
# normalize uris to webroot
sub incCSS
{

	die "deprecated";

	# return the first defined value found in arguments
	my $defined = sub { foreach my $rv (@_) { return $rv if defined $rv; } };

	# get input variables
	my ($cssfile, $config, $deps) = @_;

	# should we really import the data
	# implement special case for libsass (scss)
	my $no_import = undef;

	# find the css files
	# support for libsass
	unless (-e $cssfile)
	{
		# try different extensions in order
		foreach my $ext ('scss', 'css')
		{
			my $dir = dirname $cssfile;
			my $name = basename $cssfile;

			# check for extension only
			if (-e join('.', join('/', $dir, $name), $ext))
			{ $cssfile = join('.', join('/', $dir, $name), $ext); }
			# check for special libsass case
			elsif (-e join('.', join('/', $dir, '_' . $name), $ext))
			{
				$no_import = $cssfile;
				# detected a scss partial import
				# but still fallow to really learn about
				# all the dependencies (just for watchdog)
				$cssfile = join('.', join('/', $dir, '_' . $name), $ext);
			}
		}
	}

	# read complete css file
	my $data = readfile($cssfile);

	# collect every include within array
	push @{$deps}, $cssfile if $deps;

	# die with an error message that css file is not found
	die "css import <$cssfile> could not be read: $!\n" unless $data;

	# change all web uris in the stylesheet to absolute local paths
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(importURI($1, dirname($cssfile), $config))/egm;

	# change current working directory so we are able
	# to find further includes relative to the directory
	my $dir = RTP::Webmerge::Path->chdir(dirname($cssfile));

	# resolve all css imports and include the stylesheets (recursive resolve url paths)
	if ($config->{'import-css'})
	{
		# find import statements
		${$data} =~
		s/
			\@import\s+$re_import
		/
			# call recursive
			${ incCSS (
				# change uri to be relative
				# to the current input file
				importURI(
					# only one match will be found
					$defined->($1, $2, $3, $4, $5),
					# normalize to current css
					dirname($cssfile),
					$config
				),
				# EO importURI
				$config,
				$deps
			) }
			# EO incCSS
		/gmex;
	}
	# EO if conf import-css

	# implementation for special case (libsas/scss)
	return \ sprintf '@import "%s";', $no_import if $no_import;

	# return scalar
	return $data;

}
# EO sub incCSS

###################################################################################################

# read a css file from the disk
# normalize uris to absolute web uris
sub readCSS
{

	# get input variables
	my ($cssfile, $config) = @_;

	# create new css input object (partly parse the css file)
	# this should be extended to support all css operations
	my $input = RTP::Webmerge::Input::CSS->new($cssfile, $config);

	# change current working directory so we are able
	# to find further includes relative to the directory
	my $dir = RTP::Webmerge::Path->chdir(dirname($cssfile));

	# render the resulting css
	my $data = $input->render;

	# get our own asset path and for all dependencies
	my (@assets) = map { $_->{'path'} } $input->assets;

	# todo: return input objects and not variables
	return wantarray ? [ $data, \@assets ] : $data;

}
# EO sub readCSS

###################################################################################################

# import the final stylesheet
# normalize uris to absolute local paths
sub importCSS
{

	# get input variables
	my ($data, $cssfile, $config) = @_;

	# check for config if we should do anything
	return $data unless $config->{'rebase-urls-in-css'};

	# change all web uris in the stylesheet to absolute local paths
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(importURI($1, undef, $config))/egm;
	# ${$data} =~ s/$re_url/wrapURL(importURI($1, dirname($cssfile), $config))/egm;

	# return as string
	return $data;

}
# EO importCSS

###################################################################################################

# export a CSS stylesheets
# normalize urls to web uris
sub exportCSS
{

	# get input variables
	my ($cssfile, $data, $config) = @_;

	# change all absolute local paths to web uris
	# also changes urls in comments (needed for the spriteset feature)
	${$data} =~ s/$re_url/wrapURL(exportURI($1, dirname($cssfile)))/egm;

	# return success
	return 1;

}
# EO sub exportCSS

###################################################################################################

# write a css file to the disk
sub writeCSS
{

	# get input variables
	my ($path, $data, $config) = @_;

	# call io function to write the file atomically
	return writefile($path, $data, $config->{'atomic'}, 1)

}
# EO sub writeCSS

###################################################################################################

# extend the configurator
use RTP::Webmerge qw(@initers);

# register initializer
push @initers, sub
{

	# get input variables
	my ($config) = @_;

	# include imported css files
	$config->{'import-css'} = 1;
	$config->{'import-scss'} = 0;

	# rebase urls within file types
	# once this feature is disabled, it shall
	# be disabled for all further includes
	$config->{'rebase-urls-in-css'} = 1;
	$config->{'rebase-urls-in-scss'} = 0;

	# rebase remaining import urls
	# only matter if import is disabled
	$config->{'rebase-imports-css'} = 1;
	$config->{'rebase-imports-scss'} = 0;

	# should we use absolute urls
	# otherwise includes will be relative
	# for this option we need to webroot path
	$config->{'absoluteurls'} = 0;

	# return additional get options attribute
	return (
		'import-css!' => \ $config->{'cmd_import-css'},
		'import-scss!' => \ $config->{'cmd_import-scss'},
		'rebase-urls-in-css!' => \ $config->{'cmd_rebase-urls-in-css'},
		'rebase-urls-in-scss!' => \ $config->{'cmd_rebase-urls-in-scss'},
		'rebase-imports-css!' => \ $config->{'cmd_rebase-imports-css'},
		'rebase-imports-scss!' => \ $config->{'cmd_rebase-imports-scss'},
		'absoluteurls!' => \ $config->{'cmd_absoluteurls'}
	);

};
# EO plugin initer

###################################################################################################
###################################################################################################
1;
