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

# define our version string
BEGIN { $RTP::Webmerge::Compile::CSS::VERSION = "0.70" }

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

# create regulare expression to match css selectors
my $re_css_name = qr/[_a-zA-Z][_a-zA-Z0-9\-]*/;

# create matchers for the various css selector types
my $re_css_id = qr/\#$re_css_name/; # select single id
my $re_css_tag = qr/(?:$re_css_name|\*)/; # select single tag
my $re_css_class = qr/\.$re_css_name/; # select single class
my $re_css_pseudo = qr/\:{1,2}$re_css_name/; # select single pseudo

# create expression to match a single rule
# example : DIV#id.class1.class2:hover
my $re_css_single = qr/(?:
	  $re_css_pseudo
	| $re_css_class+ $re_css_pseudo?
	| $re_css_id $re_css_class* $re_css_pseudo?
	| $re_css_tag $re_css_id? $re_css_class* $re_css_pseudo?
)/x;

# create expression to match complex rules
# example #id DIV.class FORM A:hover
my $re_css_selector = qr/$re_css_single(?:(?:\s*>\s*|\s+)$re_css_single)*/;

# create expression to match multiple complex rules
# example #id DIV.class FORM A:hover, BODY DIV.header
my $re_css_selectors = qr/$re_css_selector(?:\s*,\s*$re_css_selector)*/;

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

		# remove spare measurement unit
		# compress 0px/0em/0pt/0% to zero
		s/\b0(?:px|\%|em|pt)(?=\s|\b|\Z|;|,)/0/gm;

		# compress colors doublets whenever possible
		# example: #CC3399 -> #C39
		s/$re_colors_doublet/'#'.substr($1,1).substr($2,1).substr($3,1)/gemi;

		# normalize colors to lowercase (good for gzip compression)
		s/\#([0-9A-Fa-f]{6})(?=\s|\Z|;|,)/'#' . lc($1)/egm;
		s/\#([0-9A-Fa-f]{3})(?=\s|\Z|;|,)/'#' . lc($1)/egm;

		# unwrap quoted strings where ever possible (like for urls, fonts)
		my $unwrap = sub
		{
			($_[1] =~ m/\s/mg || $_[1] eq "")
				? $_[0].$_[1].$_[0] : $_[1]
		};

		s/\"([^\"]*)\"/$unwrap->('"', "$1")/egx;
		s/\'([^\']*)\'/$unwrap->("'", "$1")/egx;

	}
	# EO each property

	# join the content back together
	$content = join(';', @properties);

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# normalize / sort selectors so we can match them correctly
	my $sel_sort = sub { return join(',', sort split(/\s*,\s*/, $_[0])); };
	$content =~ s/($re_css_selectors)(\s*\{)/$sel_sort->($1) . "\n" . $2/egmx;

	# remove selectors with empty css style definitions
	$content =~ s/$re_css_selectors\s*\{(?:\s*|\s*\/\*.*?\*\/\s*)}//gm;

	# get all used css selectors within this css context
	my %selectors; $selectors{$1} = 1 while($content =~ m/($re_css_selectors)\s*{/g);

	# try to merge same selectors that fallow each other
	# foreach my $selector (keys %selectors)
	# {
	# 	1 while
	# 	(
	# 		$content =~
	# 		s/
	# 			(?:(?<=})|\A)\s*
	# 			\Q$selector\E\s*{([^\}]+)}
	# 			\s*
	# 			\Q$selector\E\s*{([^\}]+)}
	# 		/
	# 			$selector . '{' . $1 . ';' . $2 . '}'
	# 		/egx
	# 	);
	# }

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# remove leading zero for float numbers (ie 0.5 => .5)
	$content =~ s/\b0+(\.[0-9]+(?:px|\%|em|pt|s)?)(?=\s|\b|\Z|;|,)/$1/gm;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# shorten redundant margin/padding definitions
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

	# fix for font face format (must be wrapped within quotes)
	# this might not be in the correct module but can avoid a bug
	$content =~ s/format\s*\(\s*([^\)]+)\s*\)/format("$1")/gx;

	#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	# remove unnecessary whitespace
	$content =~ s/\s*([\,\:\;\{\}\!])\s*/$1/gm;

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