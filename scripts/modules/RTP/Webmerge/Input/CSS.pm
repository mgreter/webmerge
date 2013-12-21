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

sub new
{

	# get input variables
	my ($pkg, @args) = @_;

	# call parent to create object
	my $self = $pkg->SUPER::new(@args);

	# default type is css
	$self->{'type'} = 'css';

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
	# XXX -> why does that not work with rel2abs?
	my $dir = RTP::Webmerge::Path->chdir($base);

	# remove comment from raw data
	${$data} =~ s/$re_comment//gm;

	# process each import statement in data
	while(${$data} =~ m/\@import\s+$re_import/g)
	{

		# get from the various styles
		# either wrapped in url or string
		my $url = $defined->($1, $2, $3);
		my $include = $defined->($4, $5);
		my $src = $url || $include;

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
		my $abspath = rel2abs($cssfile, $base);

		# parse again, suffix may has changed (should be quite cheap)
		($name, $path, $suffix) = fileparse($cssfile, 'scss', 'css');

		# store value to object
		$self->{'name'} = $name;
		$self->{'suffix'} = $suffix;
		$self->{'directory'} = $path;
		$self->{'abspath'} = $abspath;

		# import was not wrapped with url
		# this indicates some sass partials
		if ($include && $suffix eq 'scss') { }

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

sub render
{

		my $re_url = qr/url\(\s*[\"\']?((?!data:)[^\)]+?)[\"\']?\s*\)/x;

	# get instance
	my ($self, $normalize) = @_;

	# only init once for each input
	return if ($self->{'rendered'});

	# get raw data for css
	my $data = ${$self->raw};

	# change current working directory so we are able
	# to find further includes relative to the directory
	my $dir = RTP::Webmerge::Path->chdir(dirname($self->{'path'}));

	my $cssfile = $self->{'path'};
	my $config = $self->{'config'};

	# remove comment from raw data
	# $data =~ s/$re_comment//gm;

	# make these config options local, as they should influence each other and revert automatically
	local $self->{'config'}->{'rebase-urls-in-css'} = $self->{'config'}->{'rebase-urls-in-css'};
	local $self->{'config'}->{'rebase-urls-in-scss'} = $self->{'config'}->{'rebase-urls-in-scss'};

	if ($self->{'suffix'} eq 'scss')
	{
		unless ( $self->{'config'}->{'rebase-urls-in-scss'} )
		{ $self->{'config'}->{'rebase-urls-in-css'} = 0; }
	}
	else
	{
		unless ( $self->{'config'}->{'rebase-urls-in-css'} )
		{ $self->{'config'}->{'rebase-urls-in-scss'} = 0; }
	}

	if ($self->{'suffix'} eq 'scss')
	{
		if ( $self->{'config'}->{'rebase-urls-in-scss'} )
		{
			# change all web uris in the stylesheet to absolute local paths
			# also changes urls in comments (needed for the spriteset feature)
			$data =~ s/$re_url/wrapURL(importURI($1, dirname($cssfile), $config))/egm;
		}
	}
	else
	{
		if ( $self->{'config'}->{'rebase-urls-in-css'} )
		{
			# change all web uris in the stylesheet to absolute local paths
			# also changes urls in comments (needed for the spriteset feature)
			$data =~ s/$re_url/wrapURL(importURI($1, dirname($cssfile), $config))/egm;
		}
	}


	my $process = sub
	{

		# store full match
		my $matched = $1;

		# create tmpl with whitespace
		my $tmpl = '@import %s' . $7;

		# get from the various styles
		# either wrapped in url or string
		my $url = $defined->($2, $3, $4);
		my $include = $defined->($5, $6);

		# parse path and filename first (and also the suffix)
		my ($name, $path, $suffix) = fileparse($url || $include, 'scss');

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
		my $abspath = rel2abs($cssfile);

		# parse again, suffix may has changed (should be quite cheap)
		($name, $path, $suffix) = fileparse($cssfile, 'scss', 'css');

		# store value to object
		$self->{'name'} = $name;
		$self->{'suffix'} = $suffix;
		$self->{'directory'} = $path;

		my $depconf = $self->{'config'};

		# create and load a new css input object
		my $dep = RTP::Webmerge::Input::CSS->new($abspath, $depconf);

		# change current working directory so we are able
		# to find further includes relative to the directory
		my $dir = RTP::Webmerge::Path->chdir(dirname($dep->{'path'}));

		# my $path = File::Spec->abs2rel(dirname($dep->{'path'}), dirname($self->{'path'}));

		my $rv;

		my $base = dirname($self->{'path'});


		# import was not wrapped with url
		# this indicates some sass partials
		if ($include && $suffix eq 'scss')
		{
			if ( $self->{'config'}->{'rebase-imports-scss'} )
			{ $include = exportURI(importURI($include, $base)); }
			unless ( $self->{'config'}->{'import-scss'} )
			{ return sprintf $tmpl, '"' . $include . '"'; }
			$rv = ${$dep->render($base)};
			if ( $self->{'config'}->{'rebase-urls-in-scss'} )
			{ $rv =~ s/$re_url/wrapURL(exportURI($1, undef))/egm; }
		}
		else
		{
			if ( $self->{'config'}->{'rebase-imports-css'} )
			{ $include = exportURI(importURI($include, $base)); }
			unless ( $self->{'config'}->{'import-css'} )
			{ return sprintf $tmpl, wrapURL($include); }
			$rv = ${$dep->render($base)};
			if ( $self->{'config'}->{'rebase-urls-in-css'} )
			{ $rv =~ s/$re_url/wrapURL(exportURI($1, undef))/egm; }

		};

		return $rv;

	};

	# process each import statement in data
	$data =~ s/

		(\@import\s+$re_import)

	/

		$process->();

	/gmex;

	if ($self->{'suffix'} eq 'scss')
	{
		if ( $self->{'config'}->{'rebase-urls-in-scss'} )
		{ $data =~ s/$re_url/wrapURL(exportURI($1, undef))/egm; }
	}
	else
	{
		if ( $self->{'config'}->{'rebase-urls-in-css'} )
		{ $data =~ s/$re_url/wrapURL(exportURI($1, undef))/egm; }
	}

	# return cached copy of data
	return $self->{'rendered'} = \ $data;

}

# register class/package in type dispatcher
$RTP::Webmerge::Input::types{'css'} = __PACKAGE__;
$RTP::Webmerge::Input::types{'scss'} = __PACKAGE__;

###################################################################################################
###################################################################################################
1;

__DATA__

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

