################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File::CSS::Embed;
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::Webmerge qw(options);
################################################################################
# embed imported files and partials
# partials are not wrapped inside urls
################################################################################

options('css-imports', '!', 1);
options('css-partials', '!', 1);
options('scss-imports', '!', 1);
options('scss-partials', '!', 1);
options('sass-imports', '!', 1);
options('sass-partials', '!', 1);

################################################################################

my @variants = (
	'%s', '_%s',
	'%s.scss', '_%s.scss',
	'%s.sass', '_%s.sass',
	'%s.css', '_%s.css',
);

################################################################################
use OCBNET::CSS3::Regex::Base qw($re_import unquot);
use OCBNET::CSS3::Regex::Comments qw($re_comment $re_sass_comment);
################################################################################
use File::Spec::Functions qw(catfile);
use File::Basename qw(fileparse);
################################################################################

sub resolver
{

	# get arguments
	my ($node, $uri) = @_;

	# implement remote file loading here
	return $uri if $uri =~ m/^[a-zA-Z]\:\/\//;

	# parse uri into it's parts
	my ($name, $root) = fileparse($uri);

	foreach my $path (
		catfile($node->workroot, $root),
		catfile($node->dirname, $root)
	) {
		foreach my $srch (@variants)
		{
			if (-e catfile($path, sprintf($srch, $name)))
			{ return catfile($path, sprintf($srch, $name)); }
		}
	}

	return $uri;

}

################################################################################
use OCBNET::CSS3::URI qw(wrapUrl exportUrl fromUrl);
################################################################################

sub resolve
{

	# get arguments
	my ($node, $data, $srcmap) = @_;

	# defaults to multiline only
	my $re_comments = $re_comment;

	# also allow single line comment for sass/scss
	if ($node->ext eq 'sass' || $node->ext eq 'scss')
	{ $re_comments = $re_sass_comment; }

	my $re_proto = qr/^(?:[a-z]+\:)?\/\//;

	# embed further includes/imports
	${$data} =~ s/(?:($re_comments)|$re_import)/

		# ignore comments
		if (defined $1) { $1 }
		# parse further
		else
		{

			# location
			my $uri;

			# store match
			my $all = $&;

			# get unquoted url
			if (exists $+{uri})
			{ $uri = unquot($+{uri}); }
			elsif (exists $+{url})
			{ $uri = unquot($+{url}); }
			# resolve partials only for uri
			my $resolve = exists $+{uri};

			$uri =~ s|^file\:\/\/\/||;

			# check if we have a tcp protocol
			if ($uri =~ m|^$re_proto|i)
			{
				return wrapUrl($uri);
			}

			# resolve the uri if it has been requested
			$uri = $node->resolver($uri) if $resolve;

			# create template to check for specific option according to import type
			my $cfg = sprintf '%s-%s', 'css', exists $+{uri} ? 'partials' : 'imports';

			# check if we should embed this import
			if ($node->option( $cfg ))
			{

				# create a new xml input node under the current input node
				my $css = OCBNET::Webmerge::IO::File::CSS->new($node, $uri);

				# read data from file
				my $data = $css->read;

				# assertion: read should protect us from this pitfall
				# die "css pitfall" unless ${$data} =~m ~(?:;|\n)\s*\Z~;

				die "sass2scss" if $css->ext eq 'sass';

				# embed content
				${$data};

			}

			# leave unchanged
			else { $all }
		}

	/ge;
	# EO each @import

	# return reference
	return $data;

}
# EO resolve

################################################################################
################################################################################
1;
