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
use OCBNET::Spritesets::CSS::Parser::Base qw($re_comment);
use OCBNET::Spritesets::CSS::Parser::Selectors qw($re_css_selector_rules);

####################################################################################################


sub fromPosition
{

	# get position string
	my ($position) = @_;

	# default to left/top position
	return 0 unless (defined $position);

	# allow keywords for left and top position
	return 0 if ($position =~ m/^(?:top|left)$/i);

	# return the parsed pixel number if matched
	return $1 if ($position =~ m/^($re_number)(?:px)?$/i);

	# right/bottom are the only valid keywords
	# for the position for most other functions
	return 'right' if ($position =~ m/^right$/i);
	return 'bottom' if ($position =~ m/^bottom$/i);

	# die with a fatal error for invalid positions
	die "unknown background position: <$position>";

}
# EO sub fromPosition

sub isNumber { $_[0] =~ m/^$re_number$/; }
sub toUrl { sprintf("url('%s')", $_[0]); }
sub toPx { sprintf '%spx', $_[0]; }

sub fromUrl
{
	my ($url) = @_;
	$url =~ s/^\s*url\(\s*(.*?)\s*\)\s*$/$1/m;
	$url =~ s/^\"(.*?)\"\z/$1/m;
	$url =~ s/^\'(.*?)\'\z/$1/m;
	return $url;
}

sub fromPx
{
	return unless defined $_[0];
	$_[0] =~ m/($re_number)px/i ? $1 : $_[0];
}

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

	# assertion in any case (should not happen - dev)
	die "Fatal: not everything parsed" if ${$data} ne '';

	# put all blocks in a flat array
	my @blocks = @{$self->blocks};
	for (my $i = 0; $i < scalar(@blocks); $i ++)
	{ push @blocks, @{$blocks[$i]->blocks}; }

	$self->{'others'} = [];
	$self->{'selectors'} = [];

	# find selector blocks
	foreach my $block (@blocks)
	{
		if ($block->head =~ m/^\s*(?:$re_comment|$re_css_selector_rules|\s+)+$/s)
		{ push @{$self->{'selectors'}}, $block } else { push @{$self->{'others'}}, $block }
	}

	# now process each selector and parse options
	foreach my $other (@blocks)
	{

		# get only the head to parse it
		my $head = $other->head;

		# parse comments for sprite set definitions
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
		}

	}
	# EO each other

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

	# now process each selector and setup references
	foreach my $selector (@{$self->{'selectors'}})
	{
		my $id = $selector->options->get('css-id');
		$self->{'ids'}->{$id} = $selector if defined $id;
	}

	# now process each selector and setup references
	foreach my $selector (@{$self->{'selectors'}})
	{
		my $id = $selector->options->get('css-ref');
		$selector->{'ref'} = $self->{'ids'}->{$id} if defined $id;
	}

	# step 0 - create spritesets to fill in sprites
	# step 1 - parse all sprites and fill spritesets
	# step 2 - adjust background css for sprite blocks
	sub snap
	{
			return unless defined $_[0];
			my $rest = $_[0] % $_[1];
			$_[0] += $_[1] - $rest if $rest;
		}

	# now process each selector and setup sprites
	foreach my $selector (@{$self->{'selectors'}})
	{
		# get the id of the spriteset to put this in
		my $id = $selector->option('sprite-ref') || next;
		# create a new sprite and setup most options
		my $sprite = new OCBNET::Spritesets::Sprite({
			'debug' => $self->{'config'}->{'debug'},
			'filename' => fromUrl($selector->style('background-image')),
			'size-x' => fromPx($selector->style('background-size-x')) || undef,
			'size-y' => fromPx($selector->style('background-size-y')) || undef,
			'enclosed-x' => fromPx($selector->style('width') || 0) || 0,
			'enclosed-y' => fromPx($selector->style('height') || 0) || 0,
			'repeat-x' => $selector->style('background-repeat-x') || 0,
			'repeat-y' => $selector->style('background-repeat-y') || 0,
			'position-x' => fromPosition($selector->style('background-position-x') || 0),
			'position-y' => fromPosition($selector->style('background-position-y') || 0)
		});

		# prepare the spriteset position
		$sprite->{'spriteset-x'} = $sprite->positionX;
		$sprite->{'spriteset-y'} = $sprite->positionY;

		snap($sprite->{'w'}, $sprite->scaleX);
		snap($sprite->{'h'}, $sprite->scaleY);
		snap($sprite->{'width'}, $sprite->scaleX);
		snap($sprite->{'height'}, $sprite->scaleY);

		# normalize left/top position to px
		# only special case is right/bottom
		if ($sprite->{'spriteset-x'} =~ m/^($re_number)px$/i)
		{ $sprite->{'spriteset-x'} = $1; }
		elsif ($sprite->{'spriteset-x'} =~ m/^top$/i)
		{ $sprite->{'spriteset-x'} = 0; }
		if ($sprite->{'spriteset-y'} =~ m/^($re_number)px$/i)
		{ $sprite->{'spriteset-y'} = $1; }
		elsif ($sprite->{'spriteset-y'} =~ m/^left$/i)
		{ $sprite->{'spriteset-y'} = 0; }

		# store sprite object on selector
		$selector->{'sprite'} = $sprite;

		# create dimensions object and fill them in
		my %dim; foreach my $dim ('width', 'height')
		{
			my $val = fromPx($selector->style($dim) || 0);
			my $min = fromPx($selector->style('min-' . $dim));
			my $max = fromPx($selector->style('max-' . $dim));
			$val = $max if defined $max && $val < $max; # extend
			$val = $max if defined $max && $val > $max; # range
			$val = $min if defined $min && $val < $min; # range
			$dim{$dim} = { 'min' => $min, 'max' => $max, 'val' => $val };
		}

		my $padding_top = fromPx($selector->style('padding-top') || 0) || 0;
		my $padding_left = fromPx($selector->style('padding-left') || 0) || 0;
		my $padding_right = fromPx($selector->style('padding-right') || 0) || 0;
		my $padding_bottom = fromPx($selector->style('padding-bottom') || 0) || 0;

		my $isSmaller = {
			'width' => $sprite->width < $dim{'width'}->{'val'},
			'height' => $sprite->height < $dim{'height'}->{'val'}
		};

		# we have a box with the dimensions of $dim$
		# setup sprite according to spriteset
		# also prepare for background positioning

		# create padding if it's offset from top/left
		unless ($sprite->{'spriteset-x'} =~ m/^right$/i)
		{
			# add some padding to fill the empty space
			$sprite->{'padding-left'} += $sprite->{'spriteset-x'};
			$sprite->{'padding-right'} = $dim{'width'}->{'val'} - $sprite->width / $sprite->scaleX + $padding_left + $padding_right - $sprite->{'spriteset-x'};
		}
		# is right but has fixed dimension
		elsif ($sprite->isFixedX)
		{
			$sprite->{'spriteset-x'} = $dim{'width'}->{'val'} - $sprite->width / $sprite->scaleX + $padding_left + $padding_right;
			$sprite->{'padding-left'} = $dim{'width'}->{'val'} - $sprite->width / $sprite->scaleX + $padding_left + $padding_right;
		}
		unless ($sprite->{'spriteset-y'} =~ m/^bottom$/i)
		{
			# add some padding to fill the empty space
			$sprite->{'padding-top'} += $sprite->{'spriteset-y'};
			$sprite->{'padding-bottom'} = $dim{'height'}->{'val'} - $sprite->height / $sprite->scaleY + $padding_top + $padding_bottom - $sprite->{'spriteset-y'};
		}
		# is right but has fixed dimension
		elsif ($sprite->isFixedY)
		{
			$sprite->{'spriteset-y'} = $dim{'height'}->{'val'} - $sprite->height / $sprite->scaleY + $padding_top + $padding_bottom;
			$sprite->{'padding-top'} = $dim{'height'}->{'val'} - $sprite->height / $sprite->scaleY + $padding_top + $padding_bottom;
		}

		$sprite->{'padding-top'} *= $sprite->scaleY;
		$sprite->{'padding-left'} *= $sprite->scaleX;
		$sprite->{'padding-right'} *= $sprite->scaleX;
		$sprite->{'padding-bottom'} *= $sprite->scaleY;

		$sprite->{'padding-top'} = 0 if $sprite->{'padding-top'} < 0;
		$sprite->{'padding-left'} = 0 if $sprite->{'padding-left'} < 0;
		$sprite->{'padding-right'} = 0 if $sprite->{'padding-right'} < 0;
		$sprite->{'padding-bottom'} = 0 if $sprite->{'padding-bottom'} < 0;

		# add this sprite to the given spriteset
		unless ($self->{'spritesets'}->{$id})
		{ warn sprintf "unknown sprite id <%s>\n", $id; }
		else { $self->{'spritesets'}->{$id}->add($sprite); }

	}
	# EO each selector

	# return object
	return $self;

}

####################################################################################################

sub process
{

	# get passed arguments
	my ($self) = @_;

	# now process each selector and setup sprites
	foreach my $selector (@{$self->{'selectors'}})
	{
		# check if this selector is configured for a sprite
		next unless defined $selector->option('sprite-ref');
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
		my $position = $sprite->offset;

		################################
		################################
		################################

		my $bg_pos_x = $sprite->{'spriteset-x'};
		my $bg_pos_y = $sprite->{'spriteset-y'};

		die "no x" unless defined $bg_pos_x;
		die "no y" unless defined $bg_pos_y;

		my $_pos_y = (($position->{'y'} || 0) + $sprite->{'padding-top'}) / $sprite->scaleY;
		my $_pos_x = (($position->{'x'} || 0) + $sprite->{'padding-left'}) / $sprite->scaleX;

		unless ($bg_pos_y =~ m/^bottom$/i)
		{
			$bg_pos_y = toPx($bg_pos_y - $_pos_y);
		}

		unless ($bg_pos_x =~ m/^right$/i)
		{
			$bg_pos_x = toPx($bg_pos_x - $_pos_x);
		}


		my $padding_top = fromPx($selector->style('padding-top') || 0) || 0;
		my $padding_left = fromPx($selector->style('padding-left') || 0) || 0;
		my $padding_right = fromPx($selector->style('padding-right') || 0) || 0;
		my $padding_bottom = fromPx($selector->style('padding-bottom') || 0) || 0;

		#snap($padding_top, $sprite->scaleY);
		#snap($padding_left, $sprite->scaleX);
		#snap($padding_right, $sprite->scaleX);
		#snap($padding_bottom, $sprite->scaleY);

		my @positions = (
			$bg_pos_x,
			$bg_pos_y
		);


		my $declarations = [];

		# check if sprite was distributed
		# if it has no parent it means the
		# sprite has not been included yet
		unless ($sprite->{'parent'})
		{
			# check for debug mode on canvas or sprite
			if ($canvas->{'debug'} || $sprite->{'debug'})
			{
				# make border dark red
				push(@{$declarations}, [
					'border-color',
					':rgb(192, 128, 128) !important;',
				]);
				# make background redish
				push(@{$declarations}, [
					'background-color',
					':rgba(255, 0, 0, 0.125) !important;',
				]);
			}
		}
		# sprite was distributed
		else
		{

			# parse body into declarations (render will use these later)
			$selector->{'declarations'} = $parse_declarations->(\$selector->body);

			# remove all background declarations now
			@{$selector->{'declarations'}} = grep {
				not $_->[2] =~ m/^\s*background(?:\-[a-z0-9])*/is
			} @{$selector->{'declarations'}};

			# push new declarations
			push(@{$declarations},
				[
					'background-position',
					':' . ($sprite->{'sprite-position'} || join(' ', @positions)) . ';'
				],
				[
					'background-image',
					':' . toUrl($url) . ';'
				],
				[
					'background-repeat',
					': no-repeat;'
				],
				[
					'background-size',
					': ' . (($canvas->width ) / $sprite->{'scale-x'}) . 'px '
					     . (($canvas->height ) / $sprite->{'scale-y'}) . 'px;'
				]
			);
		}

		################################
		################################
		################################

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
