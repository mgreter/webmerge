###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Input::CSS;
###################################################################################################

use Carp;
use strict;
use warnings;

use RTP::Webmerge::Path qw(dirname basename $directory);
use File::Basename qw(fileparse);

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Input::CSS::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(); }

# define our functions to be exported
BEGIN { our @EXPORT_OK = qw(); }

# define our functions to be exported
BEGIN { our @ISA = qw(RTP::Webmerge::Input); }

###################################################################################################

our %import = ( css => \&importCSS, scss => \&importSCSS );

###################################################################################################

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
                    ((?:\s|\n|;)*)
/x;

# match a multiline comment
#**************************************************************************************************
our $re_comment = qr/\/\*[^\*]*\*+([^\/\*][^\*]*\*+)*\//s;

###################################################################################################

sub isabs
{
	$_[0] =~ m /^(?:\/|[a-zA-Z]:)/;
}

sub new
{

	# get input variables
	my ($pkg, @args) = @_;

	# call parent to create object
	my $self = $pkg->SUPER::new(@args);

	# default type is css
	$self->{'type'} = 'css';

	# store by base paths
	$self->{'rendered'} = {};

	# return instance
	return $self;

}

# helper function: return the first defined value found in arguments
my $defined = sub { foreach my $rv (@_) { return $rv if defined $rv; } };

use File::Spec::Functions qw(catfile rel2abs);

###################################################################################################

sub initialize
{

	# get instance
	my ($self) = @_;

}

###################################################################################################

# return dependencies
# i.e. imports for css
sub dependencies
{

	# get instance
	my ($self, $recursive) = @_;

	# only init once for each input
	if (defined $self->{'import'})
	{ return $self->{'import'}; }

	# collect file imports
	$self->{'import'} = [];

	# get raw data for css
	my $data = $self->raw;

	# base directory from current css path
	my $base = dirname($self->{'path'});

	# change current working directory so we are able
	# to find further includes relative to the directory
	# why does that not work with rel2abs?
	# https://rt.cpan.org/Public/Bug/Display.html?id=41755
	my $dir = RTP::Webmerge::Path->chdir($base);

	# remove comment from raw data
	${$data} =~ s/$re_comment//gm;

	# process each import statement in data
	while(${$data} =~ m/\@import\s+$re_import/g)
	{

		# get from the various styles
		# either wrapped in url or string
		my $wrapped = $defined->($1, $2, $3);
		my $partial = $defined->($4, $5);
		my $src = $wrapped || $partial;

		# parse path and filename first (and also the suffix)
		my ($name, $path, $suffix) = fileparse($src, 'scss');

		# search for alternative names for sass partials
		# the order may not be 100% correct, need more tests
		foreach my $srch ('_%s.scss', '_%s', '%s.scss')
		{
			if (-e catfile($path, sprintf($srch, $name)))
			{ $name = sprintf($srch, $name); last; }
		}

		# final import path for cssfile
		my $cssfile = catfile($path, $name);

		# create a new input object for the dependency
		my $abspath = rel2abs($cssfile, ${$dir});

		# parse again, suffix may has changed (should be quite cheap)
		($name, $path, $suffix) = fileparse($cssfile, 'scss', 'css');

		# store value to object
		$self->{'name'} = $name;
		$self->{'suffix'} = $suffix;
		$self->{'directory'} = $path;
		$self->{'abspath'} = $abspath;

		# import was not wrapped with url
		# this indicates some sass partials
		if ($partial && $suffix eq 'scss') { }

		# create and load a new css input object
		my $dep = RTP::Webmerge::Input::CSS->new($abspath);

		# get it's own dependencies and add them up
		push(@{$self->{'deps'}}, @{$dep->dependencies});

		# add dependency to imports
		push(@{$self->{'import'}}, $dep);

	}
	# EO while imports

	# return cached copy of data
	return $self->{'import'};

}
# EO sub dependencies

###################################################################################################

# import local webroot path
use RTP::Webmerge::Path qw(exportURI importURI);
use RTP::Webmerge::IO::CSS qw(wrapURL);

my $re_url = qr/url\(\s*[\"\']?((?!data:)[^\)]+?)[\"\']?\s*\)/x;

###################################################################################################
# adjust urls in stylesheets and include imports according to config
# base can be explicitly set to undef to not touch any urls in the file
# by default the base is set to the current working directory ($base = '.')
# you can pass specific paths to search for included imports (not urls yet)
###################################################################################################

# render urls into base
sub render
{

	# get instance and paramenters
	my ($self, $expbase) = @_;

	# set export base to current directory
	# only set this once and keep for imports
	$expbase = $directory unless $expbase;

	# get raw data for css
	my $data = ${$self->raw};

	# get the configuration hash
	my $config = $self->{'config'};

	# rebase uris to current scss or css file base (if configured)
	my $dir = $config->{'rebase-urls-in-scss'} && $self->{'suffix'} eq 'scss' ?
	          RTP::Webmerge::Path->chdir(dirname($self->{'path'})) :
	          $config->{'rebase-urls-in-css'} && $self->{'suffix'} eq 'css' ?
	          RTP::Webmerge::Path->chdir(dirname($self->{'path'})) :
	          # otherwise do not change cwd
	          RTP::Webmerge::Path->chdir('.');

	# process imports
	my $importer = sub
	{

		# store full match
		my $matched = $1;

		# create tmpl with whitespace
		my $tmpl = '@import %s' . $7;

		# get from the various styles
		# either wrapped in url or string
		my $partial = $defined->($5, $6);
		my $wrapped = $defined->($2, $3, $4);
		my $import = $partial || $wrapped;

		# parse the import filename into its parts
		my ($name, $path, $suffix) = fileparse($import, 'scss', 'css');

		# create template to check for specific option according to import type
		my $cfg = sprintf '%%s-%s-%s', $self->{'suffix'}, $partial ? 'partials' : 'imports';

		# check if we should embed this import
		if ($config->{ sprintf $cfg, 'embed' })
		{

			# load the referenced stylesheet (don't parse yet)
			# ToDo: for scss this may be from current scss file or cwd
			my $css = RTP::Webmerge::Input::CSS->new($import, $config);

			# render scss relative to old base
			return ${ $css->render($expbase) };

		}
		# otherwise preserve import statement
		else
		{

			# wrap the same type as before (add options to rewrite)
			if ($partial) { return sprintf $tmpl, '"' . $import . '"' }
			elsif ($wrapped) { return sprintf $tmpl, wrapURL($import) }

		}

	};
	# EO sub importer

	# import all relative urls to absolute paths
	# so far we are only relative to the current directory
	# current directory is changed when rebase options is set
	$data =~ s/$re_url/wrapURL(importURI($1, $directory))/egm;

	# process each import statement in data
	$data =~ s/(\@import\s+$re_import)/$importer->()/gmex;

	# export all absolute paths to relative urls again
	# make them relative to export base (pass to all imports)
	$data =~ s/$re_url/wrapURL(exportURI($1, $expbase))/egm;

	# reference data
	return \ $data;

}
# EO sub render

# register class/package in type dispatcher
$RTP::Webmerge::Input::types{'css'} = __PACKAGE__;
$RTP::Webmerge::Input::types{'scss'} = __PACKAGE__;

###################################################################################################
###################################################################################################
1;

