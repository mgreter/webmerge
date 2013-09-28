###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# this is a block where all sprites get fitted in
# the smallest available space (see packaging)
####################################################################################################
package OCBNET::Spritesets::CSS::Parser;
####################################################################################################
# 1) read
#    -> read blocks into
#    -> selectors and others
#    -> parse styles and options
#    -> setup cascading references
#    -> creates and loads all sprites
#    -> adjust some values for sprites
# 2) write
#    -> call layout
#    -> draw to canvas
# 3) process
#    -> mangling the css
# 4) render
#    -> out resulting css
####################################################################################################

use strict;
use warnings;

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

sub toPx { sprintf '%spx', @_; }
sub toUrl { sprintf "url('%s')", @_; }

####################################################################################################

sub new
{

	my ($pckg, $config) = @_;

	my $self = {
		'ids' => {},
		'head' => '',
		'blocks' => [],
		'footer' => '',
		'spritesets' => {},
		'config' => $config || {}
	};

	return bless $self, $pckg;

}

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

sub read
{

	my ($self, $data, $atomic) = @_;

	# parse all blocks and end when all is parsed
	$parse_blocks->($data, $self, qr/\A\z/);

	# assertion in any case (should never happen?)
	die "Fatal: not everything parsed" if ${$data} ne '';

	# put all blocks in a flat array
	my @blocks = @{$self->blocks};
	# this will process all and each sub block
	for (my $i = 0; $i < scalar(@blocks); $i ++)
	{ push @blocks, @{$blocks[$i]->blocks}; }

	# reset block type arrays
	$self->{'others'} = [];
	$self->{'selectors'} = [];

	# find selector blocks
	foreach my $block (@blocks)
	{
		# check if the head only consists of selector rules, comments and whitespace
		if ($block->head =~ m/^\s*(?:$re_css_selector_rules|$re_comment|\s+)+$/s)
		{ $block->{'selector'} = 1; push @{$self->{'selectors'}}, $block }
		else { $block->{'selector'} = 0; push @{$self->{'others'}}, $block }
	}

	# now process each block
	foreach my $block (@blocks)
	{

		# get only the head to parse it
		my $head = $block->head;

#			print $head, "\n";
		# parse comments for spriteset definitions
		while ($head =~ s/$re_comment//s)
		{
			# create a new css options collection
			my $options = new OCBNET::Spritesets::CSS::Collection;
			# parse declarations for this spriteset
			$parse_definition->($options, $1);
			# check if this comment is meant for us
			next unless $options->defined('sprite-id');
			# get the id for this spriteset
			my $id = $options->get('sprite-id');
			# pass debug mode from config to options
			$options->{'debug'} = $self->{'config'}->{'debug'};
			# create a new canvas object to hold all sprites
			my $canvas = new OCBNET::Spritesets::Canvas(undef, $options);
			# add this canvas to global hash object
			$self->{'spritesets'}->{$id} = $canvas;
			# associate this block with the canvas
			if ($block->{'parent'} && $block->{'selector'})
			{ $block->{'parent'}->{'canvas'} = $canvas; }
			# die $id if $block->{'parent'}->{'selector'};

			# store the id for canvas
			$canvas->{'id'} = $id;
		}

	}
	# EO each block

	# now process each selector and parse options
	foreach my $selector (@{$self->{'selectors'}})
	{

		# get only the body to parse it
		my $body = $selector->body;

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
		# get own id and reference id
		my $css_id = $selector->options->get('css-id');
		my $ref_id = $selector->options->get('css-ref');
		my $sprite_ref = $selector->options->get('sprite-ref');
		# setup relationships between references blocks
		$self->{'ids'}->{$css_id} = $selector if defined $css_id;
		# allow multiple refs per block via comma delimited list
		push @{$selector->{'ref'}}, map { $self->{'ids'}->{$_} }
		     split(/\s*,\s*/, $ref_id) if (defined $ref_id);
		# allow multiple refs per block via comma delimited list
		push @{$selector->{'ref'}}, grep { defined $_ } map { $self->{'ids'}->{$_} }
		     split(/\s*,\s*/, $sprite_ref) if (defined $sprite_ref);
	}

	# allow chaining
	return $self;

}

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

		# get the id of the spriteset to put this in
		my $id = $selector->option('sprite-ref') || next;

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

		# add this sprite to the given spriteset
		unless ($self->{'spritesets'}->{$id})
		{ warn sprintf "unknown sprite id <%s>\n", $id; }
		else { $self->{'spritesets'}->{$id}->add($sprite); }

	}

	# allow chaining
	return $self;

}

# sprites have been loaded, so we now can start to
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

# sprites have been distributed, so we now can start to
# optimize alignments, paddings and positions of sprites
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
				[ 'background-image', ': ' . $background_image . ';' ],
				[ 'background-repeat', ': ' . $background_repeat . ';' ],
			);

#			push(@{$declarations},
#				[ 'background-image', ': qweasd' . $background_image . ';' ],
#			);

#print $selector, "\n", $selector->render, "\n",
#" ---------- ", $url, "\n"; sleep 5;

		};

		# check if this selector is configured for a sprite
		if (defined $selector->option('sprite-ref'))
		{

			# get the id for the sprite set to be in
			my $id = $selector->option('sprite-ref');

			# get the spriteset object for positions
			my $canvas = $self->{'spritesets'}->{$id};

			# get the options for this spriteset
			my $spriteset = $canvas->{'options'};

			# get the url of the output image
			my $url = $spriteset->get('url');

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
				# $spriteset_y = toPx($spriteset_y - ($offset_y + $sprite->{'padding-top'}) / $sprite->scaleY);
				$spriteset_y = toPx($sprite->positionY - ($offset_y + $sprite->{'padding-top'}) / $sprite->scaleY);
			}

			# align relative to the left
			if ($sprite->alignLeft)
			{
				# $spriteset_x = toPx($spriteset_x - ($offset_x + $sprite->{'padding-left'}) / $sprite->scaleX);
				$spriteset_x = toPx($sprite->positionX - ($offset_x + $sprite->{'padding-left'}) / $sprite->scaleX);
			}

			# calculate the axes for background size
			my $background_w = toPx($canvas->width / $sprite->scaleX);
			my $background_h = toPx($canvas->height / $sprite->scaleY);

			# setup longhand values
			my $background_image = toUrl($url);
			my $background_repeat = 'no-repeat';

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

			}

		}

		################################
		################################
		################################

		next unless scalar @{$declarations};

		# render the selector bodies
		my $body = $selector->body;

		# find the first indenting to reuse it
		my $indent = $body =~ m/^([ 	]*)\S/m ? $1 : '';

		# get the traling whitespace on last line
		my $footer = $body =~ s/([ 	]*)$// ? $1 : '';

		# create a newline for footer
		$selector->{'footer'} .= ";\n";

		# add some debugger statements into css
		$selector->{'footer'} .= $indent . "/* added by webmerge */\n";

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

}


####################################################################################################
####################################################################################################
1;
