####################################################################################################
# this block stacks the sprites vertically
# or horizontally together (and aligned)
####################################################################################################
# more ideas:
# ------------------------------------------------
# implement css class inheritance (manual)
# ------------------------------------------------
# move all selectors for sprite images to
# one place to reference image only once
# this may work well with data data urls?
# where to place it to not break inheritance?
# ------------------------------------------------
# support for multiple background images (css3)
# ------------------------------------------------

# bug: media-gfx/graphicsmagick-1.3.16-r1
# fixed: media-gfx/graphicsmagick-1.3.18
####################################################################################################
package OCBNET::Spritesets;
####################################################################################################

use strict;
use warnings;

our $toUrl; # = sub { return; };
our $fromUrl; # = sub {return; };

####################################################################################################

use OCBNET::Spritesets::CSS;
use OCBNET::Spritesets::Packing;
use OCBNET::Spritesets::Block;
use OCBNET::Spritesets::Canvas;
use OCBNET::Spritesets::Container;
use OCBNET::Spritesets::Corner;
use OCBNET::Spritesets::Edge;
use OCBNET::Spritesets::Fit;
use OCBNET::Spritesets::Sprite;
use OCBNET::Spritesets::Stack;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Process::CSS::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(parseSpritesets); }

####################################################################################################

use File::Slurp;
# use Image::Magick;
use Graphics::Magick;

####################################################################################################

my @collected;
my %spritesets;

####################################################################################################

# create elemntary regular expressions
our $re_apo = qr/(?:[^\'\\]+|\\.)*/s;
our $re_quot = qr/(?:[^\"\\]+|\\.)*/s;
our $re_number = qr/[+-]?[0-9]*\.?[0-9]+/s;

# create regulare expression to match css selectors
my $re_css_name = qr/[_a-zA-Z][_a-zA-Z0-9\-]*/;
my $re_css_number = qr/(?:[0-9]+|[0-9]*\.[0-9]+)/;

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

my $re_option = qr/\w(?:\w|-)*\s*:\s*[^;]+;/;
my $re_options = qr/$re_option(?:\s*$re_option)*/m;

####################################################################################################
####################################################################################################

sub isNumber
{
	my ($number) = @_;
	return $number =~ m/^$re_number$/;
}

sub toUrl
{
	my ($url) = @_;
	$url = $toUrl->($url) if $toUrl;
	return sprintf("url('" . $url . "')");
}

sub fromUrl
{
	my ($url) = @_;
	$url =~ s/^\s*url\(\s*(.*?)\s*\)\s*$/$1/m;
	$url =~ s/^\"(.*?)\"\z/$1/m;
	$url =~ s/^\'(.*?)\'\z/$1/m;
	$url = $fromUrl->($url) if $fromUrl;
	return $url;

}

sub parseDeclaration
{

	my ($option, $code) = @_;

	# check if this is a valid sprite option block
	return unless $code =~ m/^\s*$re_options(?:\s|\n)*\z/m;

	# split all declarations
	my @declarations = map {
		[ split(/\s*:\s*/, $_, 2) ]
	} split(/\s*;\s*/, $code);

	# set option via our css system
	foreach my $item (@declarations)
	{ $option->set(lc $item->[0], $item->[1]); }

	# return object
	return $option;

}

sub negPx
{
	return (-1 * $_[0]) . 'px';
}

sub fromPx
{

	return unless defined $_[0];
	if ($_[0] =~ m/($re_number)px/i)
	{
		return $1;
	}
	else
	{
		return $_[0];
	}

}

###################################################################################################
###################################################################################################
###################################################################################################
###################################################################################################

# step 0 - parse only spritesets
# this is configured in the most outer comments
# one sprite per comment with all options is expected
#**************************************************************************************************
sub step0
{

	# code to parse
	my ($configuration) = @_;

	# create a new spriteset option object
	my $options = new OCBNET::Spritesets::CSS;

	# parse the configuration options
	parseDeclaration($options, $configuration);

	# check if configuration block was valid
	return $configuration unless $options;

	# check if sprite id is defined
	return $configuration unless $options->defined('sprite');

	# create a new canvas object to hold all sprites
	my $canvas = new OCBNET::Spritesets::Canvas(undef, $options);

	# add this canvas to global hash object
	$spritesets{$options->get('sprite')} = $canvas;

	# return unaltered
	return $configuration;

}

###################################################################################################

sub fromPosition
{

	my ($position) = @_;

	unless (defined $position)
	{
		return 0;
	}
	if ($position =~ m/^(?:top|left)$/i)
	{
		return 0;
	}
	elsif ($position =~ m/^($re_number)px$/i)
	{
		return $1;
	}
	elsif ($position =~ m/^right$/i)
	{
		return 'right';
	}

}

# step 1
#**************************************************************************************************
sub step1
{

	# get the passed variables
	my ($selector, $block) = @_;

	my $pos_x = 'left';
	my $pos_y = 'top';

	# create some css objects to hold options
	# styles are the real css style settings
	# options are the settings for this sprite
	my $styles = new OCBNET::Spritesets::CSS;
	my $options = new OCBNET::Spritesets::CSS;

	# parse all comments into our local options hash (or discharge them)
	$block =~ s/\/\*\s*(.*?)?\s*\*\//parseDeclaration($options, $1) && ""/egm;

	# remove trailing whitespace from block
	$block =~ s/(?:\A\s+|\s+\z)//gm;

	# split block into declarations
	my @declarations = map {
		[ split(/\s*:\s*/m, $_, 2) ]
	} split(/\s*;\s*/m, $block);

	# parse all css style declarations
	foreach my $css (@declarations)
	{ $styles->set(lc $css->[0], $css->[1]); }

	# get the background image from styles
	my $url = $styles->get('background-image');



	my $sprite;

	if (my $name = $options->get('sprite-ref'))
	{

		die "no url: --" . $block . "--\n" unless $url;

		my $padding_top = fromPx($options->get('sprite-padding-top') || $styles->get('padding-top') || 0);
		my $padding_left = fromPx($options->get('sprite-padding-left') || $styles->get('padding-left') || 0);
		my $padding_right = fromPx($options->get('sprite-padding-right') || $styles->get('padding-right') || 0);
		my $padding_bottom = fromPx($options->get('sprite-padding-bottom') || $styles->get('padding-bottom') || 0);

		$sprite = new OCBNET::Spritesets::Sprite(
			'filename' => fromUrl($url),
			'repeat-x' => $styles->get('background-repeat-x') || 0,
			'repeat-y' => $styles->get('background-repeat-y') || 0,
			'position-x' => $styles->get('background-position-x') || 'left',
			'position-y' => $styles->get('background-position-y') || 'top',
			'enclosed-x' => $styles->get('background-enclosed-x') || 0,
			'enclosed-y' => $styles->get('background-enclosed-y') || 0,
			'padding-right' => 0, # ($padding_left || 0) + ($padding_right || 0),
			'padding-bottom' => 0 # ($padding_top || 0) + ($padding_bottom || 0)
		);

		# if the sprite is bottom aligned
		# we do not need a padding top from height

		if (isNumber(fromPosition($sprite->{'position-x'})))
		{ $sprite->{'padding-left'} += fromPosition($sprite->{'position-x'}); }
		if (isNumber(fromPosition($sprite->{'position-y'})))
		{ $sprite->{'padding-top'} += fromPosition($sprite->{'position-y'}); }

		#$padding_top -= $sprite->{'padding-top'};
		#$padding_left -= $sprite->{'padding-left'};
		#

		if ($styles->defined('width'))
		{
			# parse the width from valid options
			my $width = fromPx($styles->get('width') || 0);
			my $minwidth = fromPx($styles->get('min-width'));
			my $maxwidth = fromPx($styles->get('max-width'));
			$width = $maxwidth if defined $maxwidth && $width < $maxwidth; # extend
			$width = $maxwidth if defined $maxwidth && $width > $maxwidth; # range
			$width = $minwidth if defined $minwidth && $width < $minwidth; # range
			$width += $padding_left + $padding_right;
			# check if the width is a valid number

			if ($sprite->{'position-x'} =~ m/^right$/i)
			{
			}

			if (isNumber($width) && $sprite->width < $width)
			{
				if ($sprite->{'position-x'} =~ m/^right$/i)
				{
					$sprite->{'padding-left'} += $width - $sprite->width - $sprite->{'padding-right'};
				}
				else
				{
					$sprite->{'padding-right'} += $width - $sprite->width - $sprite->{'padding-left'};
					$pos_x = $sprite->{'padding-left'};
				}
			}
		}


		if ($styles->defined('height'))
		{
			# parse the width from valid options
			my $height = fromPx($styles->get('height') || 0);
			my $minheight = fromPx($styles->get('min-height'));
			my $maxheight = fromPx($styles->get('max-height'));
			$height = $maxheight if defined $maxheight && $height < $maxheight; # extend
			$height = $maxheight if defined $maxheight && $height > $maxheight; # range
			$height = $minheight if defined $minheight && $height < $minheight; # range
			$height += $padding_top + $padding_bottom;
			# check if the width is a valid number
			if (isNumber($height) && $sprite->height < $height)
			{
				if ($sprite->{'position-y'} =~ m/^bottom$/i)
				{
					$sprite->{'padding-top'} += $height - $sprite->height - $sprite->{'padding-bottom'};
				}
				else
				{
					$sprite->{'padding-bottom'} += $height - $sprite->height - $sprite->{'padding-top'};
					$pos_y = $sprite->{'padding-top'};
				}
			}
		}

		$spritesets{$name}->add($sprite);

	}

	push(@collected, [$styles, $options, $sprite, \@declarations]);

	return $block;

}


# step 2
#**************************************************************************************************
sub step2
{

	my ($selector, $code) = @_;

	my ($styles, $options, $sprite, $declarations) = @{shift @collected};

	if (my $name = $options->get('sprite-ref'))
	{

		my $canvas = $spritesets{$name};

		my $spriteset = $canvas->{'options'};

		my $url = $spriteset->get('url');

		foreach my $type ('background')
		{
			my $position = $sprite->getPosition;

			my $bg_pos_x = $styles->get('background-position-x') || 'left';
			my $bg_pos_y = $styles->get('background-position-y') || 'top';

#print "=", $sprite->{'filename'}, "\n";
#print "BG POS == $bg_pos_x $bg_pos_y\n";
#print "OFFSET == ",  $position->{'x'}, " ",  $position->{'y'}, "\n";

			if ($bg_pos_x =~ m/^left$/i)
			{
				$bg_pos_x = negPx($position->{'x'} + $sprite->paddingLeft);
			}
			elsif ($bg_pos_x =~ m/^($re_number)px$/i)
			{
				$bg_pos_x = negPx($position->{'x'} -= $1 - $sprite->paddingLeft);
			}
			elsif ($bg_pos_x =~ m/^right$/i && $sprite->isFixedX)
			{
				$bg_pos_x = negPx($position->{'x'} - $sprite->paddingRight);
				if ($sprite->isFixedBoth && $sprite->notRepeating)
				{
					#$bg_pos_x = negPx($position->{'x'} - $sprite->paddingRight - $sprite->{'padding-left2'});
				}
				# warn "rigth alignment";
			}
			elsif ($bg_pos_x =~ m/^right$/i && ! $sprite->isFixedX)
			{
				warn "cannot sprite right aligned image that is flexible in width\n";
				warn " -> " . $sprite->{'filename'};
			}
			else { die "no pixel pos for x"; }

			if ($bg_pos_y =~ m/^top$/i)
			{
				$bg_pos_y = negPx($position->{'y'} + $sprite->paddingTop);
			}
			elsif ($bg_pos_y =~ m/^($re_number)px$/i)
			{
				$bg_pos_y = negPx($position->{'y'} -= $1 - $sprite->paddingTop);
			}
			elsif ($bg_pos_y =~ m/^bottom$/i && $sprite->isFixedY)
			{
				$bg_pos_y = negPx($position->{'y'} - $sprite->paddingBottom);
				if ($sprite->isFixedBoth && $sprite->notRepeating)
				{
					#$bg_pos_y = negPx($position->{'y'} - $sprite->paddingBottom - $sprite->{'padding-top2'});
				}
				# warn "bottom alignment";
			}
			elsif ($bg_pos_y =~ m/^bottom$/i && ! $sprite->isFixedY)
			{
				warn "cannot sprite bottom aligned image that is flexible in height\n";
				warn " -> " . $sprite->{'filename'};
			}
			else
			{
				die "no pixel pos for y";

			}

			unless ($bg_pos_x =~ m/^right$/i)
			{
				$bg_pos_x = negPx(- fromPx($bg_pos_x) - $sprite->{'margin-left'});
			}

			unless ($bg_pos_y =~ m/^bottom$/i)
			{
				$bg_pos_y = negPx(- fromPx($bg_pos_y) - $sprite->{'margin-top'});
			}


			# $y += ;

			my @positions = (
				$bg_pos_x,
				$bg_pos_y
			);

			#print "=> ", join(", ", @positions), "\n";

			unless ($sprite->{'parent'})
			{
				push(@{$declarations}, [
					'background-color',
					"rgba(255,0,0,0.125) !important"
				]);
			}
			else
			{

				@{$declarations} = grep {
					not $_->[0] =~ m/^background\-image/ ||
						$_->[0] =~ m/^background\-position/

				} @{$declarations};

				push(@{$declarations}, [
					'background-position',
					$sprite->{'sprite-position'} ||
						join(' ', @positions)
				]);
				push(@{$declarations}, [
					'background-image',
					toUrl($url)
				]);
			}

		};

	}

	return "\n" . join(";\n", map { "\t" . join(': ', @{$_}) } @{$declarations}) . "\n";

}

###################################################################################################
# adjust the css styles for sprites
###################################################################################################

# import functions from IO module
use RTP::Webmerge::IO qw(writefile);


sub parseSpritesets
{

	my %written;

	my ($config, $data, $from, $to, $atomic) = @_;

	local $fromUrl = $from if $from;
	local $toUrl = $to if $to;

	my $csstxt = ${$data};

	# load the css file(s) to process, could be more than one?
	# my $csstxt = read_file 'in.css', binmode => ':raw';
	# check if the css file has been loaded correctly
	die "error reading stylesheet: $!" unless defined $csstxt;

	###################################################################################################
	# parse all comments on the most outer context
	# this will parse all sprite sets that may be used
	###################################################################################################

	# make a copy of the text
	my $comments = $csstxt;

	# remove all selectors and its contents
	$comments =~ s/($re_css_selectors)(\s*{)([^}]*)(})//gm;

	# normalize newlines
	$comments =~ s/\n+\s*\n+/\n/gm;

	# trim whitespace
	$comments =~ s/(?:\A\s*|\s*\z)//;

	# parse all comments and pass to step 0
	$comments =~ s/\/\*\s*((?:.|\n)*?)?\s*\*\//step0($1)/egm;


	###################################################################################################
	# parse all style options
	# parse all sprite options
	###################################################################################################

	# parse all selectors and pass to step 1 (will extract comments himself)
	$csstxt =~ s/($re_css_selectors)(\s*{)([^}]*)(})/$1.$2.step1($1, $3).$4/egm;

	###################################################################################################
	# generate the sprite sets
	###################################################################################################

	foreach my $name (keys %spritesets)
	{

		my $canvas = $spritesets{$name};
		my $options = $canvas->{'options'};

		die "no sprite image defined for <$name>" unless $options->defined('sprite-image');

		$options->set('url', fromUrl($options->get('sprite-image')));
		$options->set('sprite-url', toUrl($options->get('url')) );

		my $image = $canvas->layout->draw;

		if ($image)
		{
			my $url = $options->get('sprite-url');
			$image->Set(magick => 'png');
			my $blob = $image->ImageToBlob();
			my $file = fromUrl($url);
			if ($atomic->{$file})
			{
				# file has already been written
				if (${$atomic->{$file}->[0]} ne $blob)
				{

					# open(my $fh1, ">", 'out1.tst');
					# open(my $fh2, ">", 'out2.tst');

					# print $fh1 ${$atomic->{$file}->[0]};
					# print $fh2 $blob;

					# die "cannot write same file with different content: $file";

					# strange enough this can happen with spritesets
					# the differences are very subtile, but no idea why
					warn "writing same file with different content: $file\n";

				}
				else
				{
					warn "writing same file more than once: $file\n";
				}
			}
			else
			{
				my $handle = writefile($file, \$blob, $atomic, 1);
				unless (exists $written{'png'})
				{ $written{'png'} = []; }
				push(@{$written{'png'}}, $handle);
			}

		}

	}

	###################################################################################################
	###################################################################################################

	# parse all selectors and pass to step 2 (will extract comments himself)
	$csstxt =~ s/($re_css_selectors)(\s*{)([^}]*)(})/$1.$2.step2($1, $3).$4/egm;

	###################################################################################################
	###################################################################################################

	foreach my $set (keys %spritesets)
	{ $spritesets{$set}->debug(); }

	###################################################################################################
	###################################################################################################

	return [\$csstxt, \%written];

	###################################################################################################
	###################################################################################################

}

###################################################################################################



###################################################################################################
###################################################################################################


####################################################################################################
####################################################################################################
1;
