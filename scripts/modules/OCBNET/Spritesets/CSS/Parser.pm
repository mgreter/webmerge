###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# this is a block which represents a stylesheet
# a stylesheet can contain multiple spritesets
# we will take care of reading and mangling the
# styles for background images regarding spritesets
####################################################################################################
package OCBNET::Spritesets::CSS::Parser;
####################################################################################################
#  my $css = OCBNET::Spritesets::CSS::Parser->new($config);
#  $css->read($data)->rehash->load;
#  $css->optimize->distribute->finalize;
#  my $written = $css->write($writer);
#  my $data = $css->process->render;
####################################################################################################

use strict;
use warnings;

####################################################################################################

# load function from core module
use List::MoreUtils qw(uniq);

####################################################################################################

# we are ourself the root css block
BEGIN { use base 'OCBNET::Spritesets::CSS::Block'; }

####################################################################################################

# load base classes for later instantiation
require OCBNET::Spritesets::CSS::Collection;

# load dependencies and import globals and functions
use OCBNET::CSS::Parser::CSS qw($parse_blocks);
use OCBNET::CSS::Parser::CSS qw($parse_definition);
use OCBNET::CSS::Parser::Base qw($re_comment uncomment);
use OCBNET::CSS::Parser::Base qw(fromPx fromUrl fromPosition);
use OCBNET::CSS::Parser::Selectors qw($re_css_selector_rules);

####################################################################################################

# helper methods for css stuff
sub toPx { sprintf '%spx', @_; }
sub toUrl { sprintf "url('%s')", @_; }

####################################################################################################

# constructor
# ******************************************************************************
sub new
{

	# get passed variables
	my ($pckg, $config) = @_;

	# init object
	my $self = {
		# store id blocks
		'ids' => {},
		# the header part
		'head' => '',
		# all subparts
		'blocks' => [],
		# the footer part
		'footer' => '',
		# spritesets by name
		'spritesets' => {},
		# config from outside
		# only debug implemented
		'config' => $config || {}
	};

	# bless into package
	return bless $self, $pckg;

}
# EO constructor

####################################################################################################

# read some css block data
# parse out selector blocks
# ******************************************************************************
sub read
{

	# get text as data ref
	my ($self, $data) = @_;

	# parse all blocks and end when all is parsed
	$parse_blocks->($data, $self, qr/\A\z/);

	# assertion in any case (should never happen?)
	die "Fatal: not everything parsed" if ${$data} ne '';

	# put all blocks in a flat array
	my @blocks = ($self, $self->blocks);
	# this will process all and each sub block
	for (my $i = 0; $i < scalar(@blocks); $i ++)
	{ push @blocks, $blocks[$i]->blocks; }

	# make blocks unique
	@blocks = uniq @blocks;

	# reset block type arrays
	$self->{'others'} = [];
	$self->{'selectors'} = [];

	# find selector blocks
	foreach my $block (@blocks)
	{
		# check if the head only consists of selector rules, comments and whitespace
		if (uncomment($block->head) =~ m/(?:\A|;)\s*(?:$re_css_selector_rules|\s+)+$/s)
		{ $block->{'selector'} = 1; push @{$self->{'selectors'}}, $block }
		else { $block->{'selector'} = 0; push @{$self->{'others'}}, $block }
	}

	# now process each block
	# find configured spritesets
	foreach my $block (@blocks)
	{

		# get the block text
		my $body = $block->text;

		# parse comments for block options
		while ($body =~ s/$re_comment//s)
		{

			# create a new css collection object to store options
			my $options = new OCBNET::Spritesets::CSS::Collection;

			# parse options for spriteset
			$parse_definition->($options, $1);

			# check if this comment is meant for us
			next unless $options->defined('sprite-image');

			# check if the sprite image has an associated id
			die "sprite image has no id" unless $options->defined('css-id');

			# get the id of this spriteset
			my $id = $options->{'css-id'};

			# pass debug mode from config to options
			$options->{'debug'} = $self->{'config'}->{'debug'};

			# create a new canvas object to hold all sprites
			my $canvas = new OCBNET::Spritesets::Canvas(undef, $options);

			# add canvas to global hash object
			$self->spriteset($id) = $canvas;

			# associate canvas with block
			$block->{'canvas'} = $canvas;

			# store the id for canvas
			$canvas->{'id'} = $id;

		}
		# EO each comment

	}
	# EO each block

	# now process each selector and parse options
	foreach my $selector (@{$self->{'selectors'}})
	{

		# get body text to parse
		my $body = $selector->text;

		# parse all comments into options hash
		while ($body =~ s/$re_comment//s)
		{ $parse_definition->($selector->{'options'}, $1); }

		# now parse remaining style options
		$parse_definition->($selector->{'styles'}, $body);

	}
	# EO each selector

	# return object
	return $self;

}
# EO sub read

####################################################################################################

# rehash the block references
# ***************************************************************************************
sub rehash
{

	# get our object
	my ($self) = @_;

	# now process each selector and setup references
	foreach my $selector (@{$self->{'selectors'}})
	{
		# get css id for this block for inheritance
		my $css_id = $selector->options->get('css-id');
		# setup relationships between references blocks
		$self->{'ids'}->{$css_id} = $selector if defined $css_id;
	}

	# now process each selector and setup references
	foreach my $selector (@{$self->{'selectors'}})
	{
		# get own id and reference id
		my $ref_id = $selector->options->get('css-ref');
		# allow multiple refs per block via comma delimited list
		push @{$selector->{'ref'}}, map { $self->{'ids'}->{$_} }
		     split(/\s*,\s*/, $ref_id) if (defined $ref_id);
		# remove undefined references (maybe print a warning)
		@{$selector->{'ref'}} = grep { defined $_ } @{$selector->{'ref'}};
	}

	# now process each selector and setup references
	foreach my $selector (@{$self->{'selectors'}})
	{
		if (! $selector->canvas && $selector->option('css-ref'))
		{ $selector->{'canvas'} = $self->spriteset($selector->option('css-ref')); }
	}

	# allow chaining
	return $self;

}
# EO sub rehash

####################################################################################################

# styles have been readed, so we now can start to
# load all sprites and setup relation to its css block
# ***************************************************************************************
sub load
{

	# get our object
	my ($self) = @_;

	# now process each selector and setup sprites
	foreach my $selector (@{$self->{'selectors'}})
	{

		# check if this selector block has a background
		next unless $selector->style('background-image');

		# get associated spriteset canvas
		my $canvas = $selector->canvas || next;

		# create a new sprite and setup most options
		my $sprite = new OCBNET::Spritesets::Sprite({
			# pass debug mode from config
			# will draw funky color backgrounds
			'debug' => $self->{'config'}->{'debug'},
			# get the filename from the url (must be "normalized")
			'filename' => fromUrl($selector->style('background-image')),
			# the size the sprite is actually shown in (from css styles)
			'size-x' => fromPx($selector->style('background-size-x')) || undef,
			'size-y' => fromPx($selector->style('background-size-y')) || undef,
			# set repeat options to decide where to ditribute
			'repeat-x' => $selector->style('background-repeat-x') || 0,
			'repeat-y' => $selector->style('background-repeat-y') || 0,
			# set enclosed options to decide where to ditribute
			'enclosed-x' => fromPx($selector->style('width') || 0) || 0,
			'enclosed-y' => fromPx($selector->style('height') || 0) || 0,
			# set position/align options to decide where to ditribute
			'position-x' => fromPosition($selector->style('background-position-x') || 0),
			'position-y' => fromPosition($selector->style('background-position-y') || 0)
		});

		# store sprite object on selector
		$selector->{'sprite'} = $sprite;

		# and also store the selector on the sprite
		$sprite->{'selector'} = $selector;

		# add sprite to canvas
		$canvas->add($sprite);

	}
	# EO each selector

	# allow chaining
	return $self;

}
# EO sub load

####################################################################################################

# sprites have not been distributed, define the paddings
# and the dimension according to the given css block styles
# ***************************************************************************************
sub optimize
{

	# get our object
	my ($self) = @_;

	# call optimize for every spriteset
	$_->optimize foreach $self->spritesets;

	# allow chaining
	return $self;

}
# EO sub optimize

####################################################################################################

# sprites have been loaded, so we now can now
# distribute all sprites to their appropriate area
# ***************************************************************************************
sub distribute
{

	# get our object
	my ($self) = @_;

	# call distribute for every spriteset
	$_->distribute foreach $self->spritesets;

	# allow chaining
	return $self;

}
# EO sub distribute

####################################################################################################

# sprites have been distributed, we now can start
# to translate bottom/right positioned sprites within
# fixed dimension boxes into top/left aligned sprites
# ***************************************************************************************
sub finalize
{

	# get our object
	my ($self) = @_;

	# call finalize for every spriteset
	$_->finalize foreach $self->spritesets;

	# allow chaining
	return $self;

}
# EO sub finalize

####################################################################################################

# just print out some debug messages
# ***************************************************************************************
sub debug
{

	# get our object
	my ($self) = @_;

	# call debug for every spriteset
	$_->debug foreach $self->spritesets;

	# allow chaining
	return $self;

}
# EO sub debug

####################################################################################################

# write out all spritesets within stylesheet
# ***************************************************************************************
sub write
{

	# get passed arguments
	my ($self, $writer) = @_;

	# status variable
	# info about all writes which is
	# used to optimize files afterwards
	my %written;

	# write all registered spritesets
	foreach my $canvas ($self->spritesets)
	{

		# get name of the canvas
		my $id = $canvas->{'id'};

		# get the css options for canvas
		# they are gathered from block comments
		my $options = $canvas->{'options'};

		# parse sprite image option and add to options for later use
		$options->set('url', fromUrl($options->get('sprite-image')));

		# assertion that we have gotten some usefull url to store the image
		die "no sprite image defined for <$id>" unless $options->get('url');

		# draw image and check for success
		if (my $image = $canvas->layout->draw)
		{
			# set the output format
			$image->Set(magick => 'png');
			# cal image to binary object
			my $blob = $image->ImageToBlob();
			# get the filename to store image
			my $file = $options->get('url');
			# write through given writer function
			$writer->($file, $blob, \%written);
		}
		# EO if successfull drawn

	}
	# EO each spriteset

	# return status variable
	return \%written;

}
# EO sub write

####################################################################################################

# process the css and prepare for write
# this mangles the original css for rendering
#**************************************************************************************************
sub process
{

	# get passed arguments
	my ($self) = @_;

	# now process each selector and setup sprites
	foreach my $selector (@{$self->{'selectors'}})
	{

		# new styles
		my %styles;

		# selector has a canvas, this means the spriteset
		# has been declares within this block, so render it
		# check this directly and not with the object method
		# this way we will really only check the local block
		if ($selector->{'canvas'})
		{

			# get canvas directly from selector block
			# this means that the spriteset was defined
			# inline and not in referenced selector block
			my $canvas = $selector->{'canvas'};

			# get the url of the spriteset image
			my $url = $canvas->{'options'}->get('url');

			# parse css body
			$selector->parse();

			# push new declarations
			$styles{'background-image'} = toUrl($url);
			$styles{'background-repeat'} = 'no-repeat';

			# remove all background styles from selector
			$selector->clean(qr/background(?!-color)(?:\-[a-z0-9])*/);

		};
		# EO each selector

		# check if this selector is configured for a sprite
		if ($selector->{'sprite'})
		{

			# get the sprite for selector
			my $sprite = $selector->{'sprite'};

			# spriteset canvas of block
			my $canvas = $selector->canvas;

			# get the url of the spriteset image
			my $url = $canvas->{'options'}->get('url');

			# get the sprite position within set
			my $offset = $sprite->offset;

			# get position offset vars
			my $offset_x = $offset->{'x'};
			my $offset_y = $offset->{'y'};

			# assertion that the values are defined
			die "no sprite x" unless defined $offset_x;
			die "no sprite y" unless defined $offset_y;

			# get pre-caluculated position in spriteset
			my $spriteset_x = $sprite->{'position-x'};
			my $spriteset_y = $sprite->{'position-y'};

			# assertion that the values are defined
			die "no spriteset x" unless defined $spriteset_x;
			die "no spriteset y" unless defined $spriteset_y;

			# calculate the axes for background size
			my $background_w = toPx($canvas->width / $sprite->scaleX);
			my $background_h = toPx($canvas->height / $sprite->scaleY);

			# align relative to the top and relative to the left
			$spriteset_y = toPx($sprite->positionY - ($offset_y + $sprite->paddingTop) / $sprite->scaleY) if $sprite->alignTop;
			$spriteset_x = toPx($sprite->positionX - ($offset_x + $sprite->paddingLeft) / $sprite->scaleX) if $sprite->alignLeft;

			# assertion that the actual background position is always a full integer
			warn "spriteset_x is not an integer $spriteset_x" unless $spriteset_x =~ m/^(?:\-?[0-9]+px|top|left|right|bottom)$/i;
			warn "spriteset_y is not an integer $spriteset_y" unless $spriteset_y =~ m/^(?:\-?[0-9]+px|top|left|right|bottom)$/i;

			# check if sprite was distributed
			# if it has no parent it means the
			# sprite has not been included yet
			unless ($sprite->{'parent'})
			{
				# check for debug mode on canvas or sprite
				if ($canvas->{'debug'} || $sprite->{'debug'})
				{
					# make border dark red and background lightly red
					$styles{'border-color'} = 'rgb(192, 128, 128) !important';
					$styles{'background-color'} = 'rgba(255, 0, 0, 0.125) !important';
				}
			}

			# sprite was distributed
			else
			{

				# parse css body
				$selector->parse;

				# add shorthand styles for sprite sizing and position
				$styles{'background-size'} = join(' ', $background_w, $background_h);
				$styles{'background-position'} = join(' ', $spriteset_x, $spriteset_y);

				# add repeating if sprite has it configured
				if ($sprite->isRepeatX && $sprite->isFlexibleX)
				{ $styles{'background-repeat'} = 'repeat-x'; }
				if ($sprite->isRepeatY && $sprite->isFlexibleY)
				{ $styles{'background-repeat'} = 'repeat-y'; }

				# remove all background styles from selector
				$selector->clean(qr/background(?!-color)(?:\-[a-z0-9])*/);

			}

		}
		# EO if has sprite

		# do we have new styles
		if (scalar %styles)
		{

			# render the selector bodies
			my $body = $selector->body;

			# find the first indenting to reuse it
			my $indent = $body =~ m/^([ 	]*)\S/m ? $1 : '	';

			# get the traling whitespace on last line
			my $footer = $body =~ s/([ 	]*)$// ? $1 : '';

			# add some debugger statements into css
			$selector->{'footer'} .= "\n" . $indent . ";/* added by webmerge */\n";

			# add these declarations to the footer to be included within block
			$selector->{'footer'} .= sprintf "%s%s: %s;\n", $indent, $_, $styles{$_} foreach keys %styles;

			# add some debugger statements into css
			$selector->{'footer'} .= $indent . "/* added by webmerge */\n";

			# append traling whitespace again
			$selector->{'footer'} .= $footer;

		}
		# EO if has styles

	}
	# EO each selector

	# make chainable
	return $self;

}
# EO sub process

####################################################################################################
# getter functions for this object
####################################################################################################

# get the spriteset by the passed key/name
# ******************************************************************************
sub spriteset : lvalue { $_[0]->{'spritesets'}->{$_[1]}; }

# get list of all spriteset objects (actualy canvas)
# ******************************************************************************
sub spritesets { return values %{$_[0]->{'spritesets'}}; }

####################################################################################################
####################################################################################################
1;
