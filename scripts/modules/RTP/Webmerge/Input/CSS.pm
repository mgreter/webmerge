###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Input::CSS;
###################################################################################################

use Carp;
use strict;
use warnings;

use RTP::Webmerge::Path qw(dirname basename $directory resolveURI);
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

my $re_url = qr/url\(\s*(?:
	\s*\"(?!data:)(?<url>$re_quot)\" |
	\s*\'(?!data:)(?<url>$re_apo)\' |
	(?![\"\'])\s*(?!data:)(?<url>[^\)]*)
)\s*\)/xi;

###################################################################################################

# parse imports with a strict match
# use same pattern as found in libsass
our $re_import = qr/
                   (?:url\(\s*(?:
                                    \s*\"(?!data:)(?<url>$re_quot)\" |
                                    \s*\'(?!data:)(?<url>$re_apo)\' |
                                    (?![\"\'])\s*(?!data:)(?<url>[^\)]*)
                            )\s*\)|
                            \s*\"(?!data:)(?<url>$re_quot)\" |
                            \s*\'(?!data:)(?<url>$re_apo)\'
                    )
                    ((?:\s|\n|;)*)
/x;

# match a multiline comment
#**************************************************************************************************
our $re_comment = qr/\/\*[^\*]*\*+(?:[^\/\*][^\*]*\*+)*\//s;

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
# EO sub initialize

###################################################################################################

my $resolver = sub
{

	my ($self, $uri, $paths) = @_;

	# parse uri into it's parts
	my ($name, $root) = fileparse($uri);

	foreach my $path (
		catfile($directory, $root),
		catfile(dirname($self->{'path'}), $root)
	)
	{
		foreach my $srch ('%s', '_%s', '%s.scss', '_%s.scss')
		{
			if (-e catfile($path, sprintf($srch, $name)))
			{ return catfile($path, sprintf($srch, $name)); }
		}
	}

	return $uri;

};
# EO sub $resolver

###################################################################################################

# return dependencies
# i.e. imports for css
sub dependencies
{

	# get instance
	my ($self, $recursive) = @_;

	# collect file imports
	$self->{'import'} = [];

	# get raw data for css
	my $data = $self->raw;

	# get the configuration hash
	my $config = $self->{'config'};

	# rebase uris to current scss or css file base (if configured)
	my $dir = $config->{'rebase-urls-in-scss'} && $self->{'suffix'} eq 'scss' ?
	          RTP::Webmerge::Path->chdir(dirname($self->{'path'})) :
	          $config->{'rebase-urls-in-css'} && $self->{'suffix'} eq 'css' ?
	          RTP::Webmerge::Path->chdir(dirname($self->{'path'})) :
	          # otherwise do not change cwd
	          RTP::Webmerge::Path->chdir('.');

	# base directory from current css path
	my $base = dirname($self->{'path'});

	# remove comment from raw data
	${$data} =~ s/$re_comment//gm;

	while (${$self->raw} =~ m/$re_url/g)
	{
		# get it's own dependencies and add them up
		push(@{$self->{'import'}}, importURI($+{url}, $directory));
	}

	# process each import statement in data
	while(${$data} =~ m/(?<!\/\/|\/\*)(\s*)(\@import\s+$re_import)/g)
	{

		# get from the various styles
		# either wrapped in url or string
		my $partial = $defined->($6, $7);
		my $wrapped = $defined->($3, $4, $5);
		my $import = $partial || $wrapped;

		# store additional space attached
		my $prefix = $1; my $postfix = $8;

		# got something with a protocol?
		if ($import =~ m/([a-z]+\:)?\/\//i)
		{
			die "got $import";
		}
		# got a regular file
		else
		{

			# resolve import filename
			# try to load scss partials
			$import = $resolver->($self, $import);

			# create and load a new css input object
			my $dep = RTP::Webmerge::Input::CSS->new($import, $config);

			# get it's own dependencies and add them up
			push(@{$self->{'deps'}}, @{$dep->dependencies});

			# add dependency to imports
			push(@{$self->{'import'}}, $dep);

		}

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
		my $matched = $2;

		# create tmpl with whitespace
		my $tmpl = '@import %s' . $8;

		# get from the various styles
		# either wrapped in url or string
		my $partial = $defined->($6, $7);
		my $wrapped = $defined->($3, $4, $5);
		my $import = $partial || $wrapped;

		# store additional space attached
		my $prefix = $1; my $postfix = $8;

		# got something with a protocol?
		if ($import =~ m/([a-z]+\:)?\/\//)
		{
			# wrap the same type as before (add options to rewrite)
			if ($partial) { return $prefix . sprintf($tmpl, '"' . $import . '"') }
			elsif ($wrapped) { return $prefix . sprintf($tmpl, wrapURL($import)) }
		}
		# got a regular file
		else
		{

			# resolve import filename
			# try to load scss partials
			$import = $resolver->($self, $import);

			# parse the import filename into its parts
			my ($name, $path, $suffix) = fileparse($import, 'scss', 'css');

			# create template to check for specific option according to import type
			my $cfg = sprintf '%%s-%s-%s', $suffix, $partial ? 'partials' : 'imports';

			# check if we should embed this import
			if ($config->{ sprintf $cfg, 'embed' })
			{

				# load the referenced stylesheet (don't parse yet)
				# ToDo: for scss this may be from current scss file or cwd
				my $css = RTP::Webmerge::Input::CSS->new($import, $config);

				# render scss relative to old base
				return "\n" . ${ $css->render($expbase) } . "\n";

			}
			# otherwise preserve import statement
			else
			{

				my $export = exportURI($import, $expbase);
				# wrap the same type as before (add options to rewrite)
				if ($partial) { return $prefix . sprintf($tmpl, '"' . $export . '"') }
				elsif ($wrapped) { return $prefix . sprintf($tmpl, wrapURL($export)) }

			}

		}

	};
	# EO sub importer

	# import all relative urls to absolute paths
	# so far we are only relative to the current directory
	# current directory is changed when rebase options is set
	$data =~ s/$re_url/wrapURL(importURI($+{url}, $directory))/egm;

	# resolve imports
	my $import = '';

	# called on actual css code
	# not called for any comment
	my $parser = sub
	{
		# create a copy to work on
		my $text = $2;
		# process each import statement in data
		# added simple protection for imports in comments
		# this will not always work and needs to be replaced
		$text =~ s/()(\@import\s+$re_import)/$importer->()/gemx;
		# return text
		return $text;
	};
	# EO $parser

	# process data to find imports
	while($data ne '' && $data =~
		s/(?:
			((?:
				# match different comments
				# obey sass comments on imports
				$re_comment|\/\/[^\n]+|\/
			)+)
			|
			((?:
				# match any other css code
				# only try to import from these
				[^\"\'\/]+|\"$re_quot\"|\'$re_apo\'
			)+)
		)/;
		# comment or whitespace
		if (defined $1) { $import .= $1; }
		# actual code or partial text
		if (defined $2) { $import .= $parser->(); }
		# reset parsed part
		'';
	/emx) {}

	# give an error message (this should never happen)
	die "CSS Import parse error\n", substr($data, 0, 60) if $data ne '';

	# export all absolute paths to relative urls again
	# make them relative to export base (pass to all imports)
	$import =~ s/$re_url/wrapURL(exportURI($+{url}, $expbase))/egm;

	# reference data
	return \ $import;

}
# EO sub render

# register class/package in type dispatcher
$RTP::Webmerge::Input::types{'css'} = __PACKAGE__;
$RTP::Webmerge::Input::types{'scss'} = __PACKAGE__;

###################################################################################################
###################################################################################################
1;

