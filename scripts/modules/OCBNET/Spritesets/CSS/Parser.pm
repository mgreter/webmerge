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

# load dependencies and import functions
use OCBNET::Spritesets::CSS::Collection;
use OCBNET::Spritesets::CSS::Parser::CSS;
use OCBNET::Spritesets::CSS::Parser::CSS qw($parse_definition);
use OCBNET::Spritesets::CSS::Parser::Base;
use OCBNET::Spritesets::CSS::Parser::Base qw($re_comment fromPx fromUrl fromPosition);
use OCBNET::Spritesets::CSS::Parser::Selectors qw($re_css_selector_rules);

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

	my ($self, $data) = @_;

	# parse all blocks and end when all is parsed
	$parse_blocks->($data, $self, qr/\A\z/);

	# assertion in any case (should never happen?)
	die "Fatal: not everything parsed" if ${$data} ne '';

	# put all blocks in a flat array
	my @blocks = ($self, @{$self->blocks});
	# this will process all and each sub block
	for (my $i = 0; $i < scalar(@blocks); $i ++)
	{ push @blocks, @{$blocks[$i]->blocks}; }

	# make blocks unique
	@blocks = uniq @blocks;

	# reset block type arrays
	$self->{'others'} = [];
	$self->{'selectors'} = [];

	# find selector blocks
	foreach my $block (@blocks)
	{
		# check if the head only consists of selector rules, comments and whitespace
		if ($block->head =~ m/(?:\A|;)\s*(?:$re_css_selector_rules|$re_comment|\s+)+$/s)
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

			# add this canvas to global hash object
			$self->{'spritesets'}->{$id} = $canvas;

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
		{
			# print "search spriteset ",$selector->option('css-ref'), "\n";
			$selector->{'canvas'} = $self->{'spritesets'}->{$selector->option('css-ref')};
		}
	}

# die $self->{'spritesets'}->{$self->option('css-ref')} if $self->option('css-ref');
#	if (my $id = $self->option('css-ref'))
#	{ return $self->{'spritesets'}->{$id}; }

	# allow chaining
	return $self;

}

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

	# call optimize for every spriteset in this stylesheet
	$_->optimize foreach (values %{$self->{'spritesets'}});

	# allow chaining
	return $self;

}
# EO sub optimize

####################################################################################################

# sprites have been loaded, so we now can now to
# distribute all sprites to their appropriate area
# ***************************************************************************************
sub distribute
{

	# get our object
	my ($self) = @_;

	# call distribute for every spriteset in this stylesheet
	$_->distribute foreach (values %{$self->{'spritesets'}});

	# allow chaining
	return $self;

}
# EO sub optimize

####################################################################################################

# sprites have been distributed, we now can start
# to translate bottom/right positioned sprites within
# fixed dimension boxes into top/left aligned sprites
# ***************************************************************************************
sub finalize
{

	# get our object
	my ($self) = @_;

	# call optimize for every spriteset in this stylesheet
	$_->finalize foreach (values %{$self->{'spritesets'}});

	# allow chaining
	return $self;

}
# EO sub finalize

####################################################################################################

sub write
{

	my %written;

	# get passed arguments
	my ($self, $writer) = @_;

	foreach my $name (keys %{$self->{'spritesets'}})
	{

		my $canvas = $self->{'spritesets'}->{$name};

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
			$writer->($file, $blob, \%written);

		}

	}

	foreach my $set (keys %{$self->{'spritesets'}})
	{ $self->{'spritesets'}->{$set}->debug(); }

	return \%written;

}

####################################################################################################

sub process
{

	# get passed arguments
	my ($self) = @_;

	# now process each selector and setup sprites
	foreach my $selector (@{$self->{'selectors'}})
	{

		# additional declarations
		my $declarations = [];

		# selector has a canvas, this means the spriteset
		# has been declares within this block, so render it
		if ($selector->{'canvas'})
		{

			my $canvas = $selector->{'canvas'};

			# get the options for this spriteset
			my $spriteset = $canvas->{'options'};

			# get the url of the output image
			my $url = $spriteset->get('url');
			$url = fromUrl($selector->option('sprite-image')) unless $url;

			my $imp = $selector->option('sprite-importance') || '';

die "no url" unless $url;

			my $background_image = toUrl($url);
			my $background_repeat = 'no-repeat';

			# parse body into declarations (render will use these later)
			$selector->{'declarations'} = $parse_declarations->(\$selector->body) unless $selector->{'declarations'};

			# remove all background declarations now
			@{$selector->{'declarations'}} = grep {
				not $_->[2] =~ m/^\s*background(?:\-[a-z0-9])*/is
			} @{$selector->{'declarations'}};

			# push new declarations
			push(@{$declarations},
				[ 'background-image', ': ' . $background_image . $imp . ';' ],
				[ 'background-repeat', ': ' . $background_repeat . $imp . ';' ],
			);

		};

		# check if this selector is configured for a sprite
		if (defined $selector->{'sprite'})
		{

			# get the id for the sprite set to be in
			my $id = $selector->canvas->{'id'};
			die "no id for sprite" unless $id;

			# get the spriteset object for positions
			my $canvas = $self->{'spritesets'}->{$id};

			# get the options for this spriteset
			my $spriteset = $canvas->{'options'};

			# get the url of the output image
			my $url = $spriteset->get('url');
			$url = fromUrl($canvas->{'options'}->get('sprite-image'));
die $url unless $url;
			# get the sprite for selector
			my $sprite = $selector->{'sprite'};

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

			# align relative to the top
			if ($sprite->alignTop)
			{
				$spriteset_y = toPx($sprite->positionY - ($offset_y + $sprite->{'padding-top'}) / $sprite->scaleY);
			}

			# align relative to the left
			if ($sprite->alignLeft)
			{
				$spriteset_x = toPx($sprite->positionX - ($offset_x + $sprite->{'padding-left'}) / $sprite->scaleX);
			}

			# calculate the axes for background size
			my $background_w = toPx($canvas->width / $sprite->scaleX);
			my $background_h = toPx($canvas->height / $sprite->scaleY);

			# setup longhand values
			my $background_image = toUrl($url);
			my $background_repeat = 'no-repeat';

			# assertion that the actual background position is always a full integer
			warn "spriteset_x is not an integer $spriteset_x" unless $spriteset_x =~ m/^(?:\-?[0-9]+px|top|left|right|bottom)$/i;
			warn "spriteset_y is not an integer $spriteset_y" unless $spriteset_y =~ m/^(?:\-?[0-9]+px|top|left|right|bottom)$/i;

			# setup shorthand values
			my $background_size = join(' ', $background_w, $background_h);
			my $background_position = join(' ', $spriteset_x, $spriteset_y);

			# check if sprite was distributed
			# if it has no parent it means the
			# sprite has not been included yet
			unless ($sprite->{'parent'})
			{
				# check for debug mode on canvas or sprite
				if ($canvas->{'debug'} || $sprite->{'debug'})
				{
					# make border dark red and background lightly red
					push(@{$declarations}, [ 'border-color', ': rgb(192, 128, 128) !important;' ]);
					push(@{$declarations}, [ 'background-color', ': rgba(255, 0, 0, 0.125) !important;' ]);
				}
			}

			# sprite was distributed
			else
			{

				# parse body into declarations (render will use these later)
				$selector->{'declarations'} = $parse_declarations->(\$selector->body) unless $selector->{'declarations'};

				# remove all background declarations now
				@{$selector->{'declarations'}} = grep {
					not $_->[2] =~ m/^\s*background(?:\-[a-z0-9])*/is
				} @{$selector->{'declarations'}};

				# push new declarations
				push(@{$declarations},
					[ 'background-size', ': ' . $background_size . ';' ],
					[ 'background-position', ': ' . $background_position . ';' ]
				);

				# push new declarations
				push(@{$declarations},
					[ 'background-image', ': ' . $background_image . ';' ],
					[ 'background-repeat', ': ' . $background_repeat . ';' ],
				) unless $selector->canvas;

				# push new declarations
				push(@{$declarations},
					[ 'background-repeat', ': ' . 'repeat-x' . ';' ],
				) if $sprite->isRepeatX && $sprite->isFlexibleX;
				# push new declarations
				push(@{$declarations},
					[ 'background-repeat', ': ' . 'repeat-y' . ';' ],
				) if $sprite->isRepeatY && $sprite->isFlexibleY;

			}

		}

		################################
		################################
		################################

		next unless scalar @{$declarations};

		# render the selector bodies
		my $body = $selector->body;

		# find the first indenting to reuse it
		my $indent = $body =~ m/^([ 	]*)\S/m ? $1 : '	';

		# get the traling whitespace on last line
		my $footer = $body =~ s/([ 	]*)$// ? $1 : '';

		# add some debugger statements into css
		$selector->{'footer'} .= "\n" . $indent . ";/* added by webmerge */\n";

		# process all new declaration for block
		foreach my $declaration (@{$declarations})
		{
			# add these declarations to the footer to be included within block
			$selector->{'footer'} .= sprintf "%s%s%s\n", $indent, @{$declaration};
		}

		# add some debugger statements into css
		$selector->{'footer'} .= $indent . "/* added by webmerge */\n";

		# append traling whitespace again
		$selector->{'footer'} .= $footer;

		################################
		################################
		################################

	}

	# make chainable
	return $self;

}

####################################################################################################
####################################################################################################
1;
