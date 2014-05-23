###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
# more ideas:
# - make selectors uppercase for gzip
# - make all declarations lowercase for gzip
# - add more logic to optimize one selector (like paddings)
###################################################################################################
package RTP::Webmerge::Compile::CSS;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################
# ToDo: Merge with spriteset css parser and create a common parser module
###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Compile::CSS::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(compileCSS); }

###################################################################################################
# setup regular expression to match various css stuff
###################################################################################################

# regular expression to find color doublets (like #CC3399)
my $re_color_doublet = qr/(?:00|11|22|33|44|55|66|77|88|99|AA|BB|CC|DD|EE|FF)/i;
my $re_colors_doublet = qr/\#($re_color_doublet)($re_color_doublet)($re_color_doublet)/i;

###################################################################################################

# load regular expression from spriteset parser
use OCBNET::CSS::Parser::Selectors qw($re_css_selector_rules);

###################################################################################################

# do the main css compilation
# this method may be usefull for others
# this module should be able to run standalone
sub compileCSS
{

	# get input variables
	my ($content, $config) = @_;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# replace multi-newlines
	$content =~ s/(?:\n|\r|\n\r|\r\n)+/\n/g;

	# trim leading whitespace
	$content =~ s/^\s+//gm;

	# trim multiline comments
	$content =~ s/\/\*(.|\n)+?\*\///gi;

	# replace multi-newline again
	$content =~ s/(?:\n|\r)+/\n/g;

	# trim leading whitespace
	$content =~ s/^\s+//gm;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	# optimize all properties first
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# split content into properties
	# this is only an approximation but should
	# solve most of the 'strange' ie behaviours
	my @properties = split (/;/, $content);

	# process each property
	foreach (@properties)
	{

		# do not optimize ie filters
		next if m/filter\s*:/;
		# do not optimize ie expressions
		next if m/:\s*expression\(\s*/;

		# compress superfluous units
		# example: 0px/0em/0pt/0% to 0
		s/\b0(?:px|\%|em|pt)(?=\s|\b|\Z|;|,)/0/gm;

		# compress colors triplets
		# example: #CC3399 -> #C39
		s/$re_colors_doublet/'#'.substr($1,1).substr($2,1).substr($3,1)/gemi;

		# normalize colors to lowercase (good for gzip compression)
		# ToDo: replace color names with their rgb counterparts
		s/\#([0-9A-Fa-f]{6})(?=\s|\Z|;|,)/'#' . lc($1)/egm;
		s/\#([0-9A-Fa-f]{3})(?=\s|\Z|;|,)/'#' . lc($1)/egm;

		# unwrap quoted strings whenever possible (like for urls, fonts)
		# there is a bug in IE where format has to be enclosed in quotes
		# we implemented a bugfix below that will re-add quotes in that case
		my $unwrap = sub
		{
			($_[1] =~ m/\s/mg || $_[1] eq "")
				? $_[0].$_[1].$_[0] : $_[1]
		};

		# call the created unwrapper method
		# for both: single and double quotes
		s/\"([^\"]*)\"/$unwrap->('"', "$1")/egx;
		s/\'([^\']*)\'/$unwrap->("'", "$1")/egx;

	}
	# EO each property

	# join the content back together
	$content = join(';', @properties);

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	# optimize with more general rules over while text
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# remove leading zero for float numbers (ie 0.5 => .5)
	$content =~ s/\b0+(\.[0-9]+(?:px|\%|em|pt|s)?)(?=\s|\b|\Z|;|,)/$1/gm;

	# shorten redundant margin/padding definitions
	# are there any four value shorthands that cannot
	# be optimized in this way? I don't know any so far!
	# unsure if we could do it for three value shorthands?
	# ie -> margin: 5px 5px 5px 5px; => margin: 5px;
	# ie -> margin: 5px 8px 5px 8px; => margin: 5px 8px;
	# ie -> margin: 5px 8px 0px 8px; => margin: 5px 8px 0px;
	$content =~ s/
		:\s*
		\b([0-9]+(?:px|\%|em|pt|s)?)(?=\s|\b|\Z|;|,)\s*
		\b([0-9]+(?:px|\%|em|pt|s)?)(?=\s|\b|\Z|;|,)\s*
		\b([0-9]+(?:px|\%|em|pt|s)?)(?=\s|\b|\Z|;|,)\s*
		\b([0-9]+(?:px|\%|em|pt|s)?)(?=\s|\b|\Z|;|,)\s*
		\;
	/
		if ($1 eq $2 && $2 eq $3 && $3 eq $4) { ":$1;"; }
		elsif ($2 eq $4 && $1 eq $3) { ":$1 $2;" }
		elsif ($2 eq $4) { ":$1 $2 $3;" }
		else { ":$1 $2 $3 $4;"; }
	/egmx;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	# optimize for css selectors and blocks
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# remove selectors with no css style definitions (empty blocks)
	$content =~ s/$re_css_selector_rules\s*\{(?:\s*|\s*\/\*.*?\*\/\s*)}//gm;

	# only do this for insane optimization levels
	if ($config->{'level'} > 4)
	{

		# normalize / sort selectors so we can match them correctly
		# this cannot have any impact, as they all reference the same block
		my $sel_sort = sub { return join(',', sort split(/\s*,\s*/, $_[0])); };
		$content =~ s/($re_css_selector_rules)(\s*\{)/$sel_sort->($1) . "\n" . $2/egmx;

		# get all used css selectors within this css context
		my %selectors; $selectors{$1} = 1 while($content =~ m/($re_css_selector_rules)\s*{/g);

		# try to merge same selectors that fallow each other
		# this is very expensive, so only do it if requested
		foreach my $selector (keys %selectors)
		{
			1 while
			(
				$content =~
				s/
					(?:(?<=})|\A)\s*
					\Q$selector\E\s*{([^\}]+)}
					\s*
					\Q$selector\E\s*{([^\}]+)}
				/
					$selector . '{' . $1 . ';' . $2 . '}'
				/egx
			);
		}
		# EO each selector

	}
	# EO if opt level > 4

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# use spriteset css parser to implement more advanced optimizations
	# - merge longhand padding/margin if all four axes are defined
	# - remove duplicate/superfluous style definitions (longhands)
	# - merge complete shorthands into a single longhand definition

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# fix for font face format (must be wrapped within quotes)
	# this might not be in the correct module but can avoid a bug
	$content =~ s/format\s*\(\s*([^\)]+)\s*\)/format("$1")/gx;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# remove unnecessary whitespace
	$content =~ s/\s*([\,\;\{\}\!])\s*/$1/gm;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# remove multiple semicolons
	$content =~ s/;+/\;/gm;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# shorten multi whitespace
	$content =~ s/\s+/ /gm;

	# remove traling whitespace
	$content =~ s/\s+\Z//gm;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# Experimental: remove unneeded chars
	$content =~ s/(?:;|\s)+([\{\}])/$1/gm;
	$content =~ s/([\{\}])(?:;|\s)+/$1/gm;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# pretty print the packed css styles
	if ($config->{'pretty'})
	{
		$content =~ s/([{}])/\n$1\n/gm;
		$content =~ s/\n+/\n/gm;
	}

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	# _clean(\$content) or die 'could not clean data';
	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# return compiled
	return $content;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

}
# EO sub compileCSS

###################################################################################################
###################################################################################################
1;