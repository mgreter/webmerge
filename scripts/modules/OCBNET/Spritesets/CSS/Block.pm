###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# a css block inside curly braces or root and can be
# anything, from a selector to a media-query declaration
# any block can have any kind of sublocks, we dont care
# we do not really support the setting of styles directly
# but you should be able to safely add new style definitions
####################################################################################################
package OCBNET::Spritesets::CSS::Block;
####################################################################################################

use strict;
use warnings;

####################################################################################################

use OCBNET::Spritesets::CSS::Collection;
use base 'OCBNET::Spritesets::CSS::Collection';

####################################################################################################

# constructor
#**************************************************************************************************
sub new
{

	# get class name
	# parent is optional
	my ($pckg, $parent) = @_;

	# create new object
	my $block = {

		# defines type of block
		# can i.e. be css selectors
		'head' => '',

		# optional sub-blocks
		'blocks' => [],

		# optional footer text
		'footer' => '',

		# the actual parsed styles (use getter methods)
		'styles' => new OCBNET::Spritesets::CSS::Collection,
		'options' => new OCBNET::Spritesets::CSS::Collection

	};

	# parent is optional
	if (defined $parent)
	{
		# connect parent node
		$block->{'parent'} = $parent;
		# we are one of our parents children
		push(@{$parent->{'blocks'}}, $block);
	}

	# bless into correct package
	return bless $block, $pckg;

}
# EO constructor

####################################################################################################

# render the mangled css
# must be the same as on read
# if no styles have been added
sub render
{

	# get block to render
	my ($block) = @_;

	# first add the header
	my $css = $block->head;

	# check if we have any sub-blocks
	if (scalar(@{$block->blocks}))
	{

		# create a new scope if we are a child
		$css .= "{" if $block->parent;

		# render and add the block body
		$css .= $block->body;

		# finally add the footer
		$css .= $block->footer;

		# close the scope if we are a child
		$css .= "}" if $block->parent;

	}
	# EO if has sub-blocks

	# return the css
	return $css;

}
# EO sub render

####################################################################################################

# render the body css code
# either mangled or original
#**************************************************************************************************
sub body
{

	# init variable
	my $css = '';

	# get block to render
	my ($block) = @_;

	# check if we have any declarations
	# this can overrule the whole rendering
	# it is used to mangle only certain blocks
	# without interferring with any other blocks
	if ($block->{'declarations'})
	{
		# put back all declarations
		$css .= join "", map
			{ sprintf "%s%s", @{$_}; }
				@{$block->{'declarations'}};
	}
	# render the original code
	else
	{
		foreach my $child (@{$block->blocks})
		{
			$css .= $child->render
		}
	}

	# return the css
	return $css;

}
# EO sub body

sub head { $_[0]->{'head'} }
sub blocks { $_[0]->{'blocks'} }
sub parent { $_[0]->{'parent'} }
sub footer { $_[0]->{'footer'} }

sub styles { $_[0]->{'styles'} }
sub options { $_[0]->{'options'} }

####################################################################################################
# getter methods for block styles and options
####################################################################################################

# get parsed css style by name
#**************************************************************************************************
sub style
{

	# get passed variables
	my ($self, $option) = @_;

	# do we have a valid style in current block
	if (defined $self->styles->get($option))
	{
		# get style from current block styles
		return $self->styles->get($option);
	}
	# maybe we have a reference block
	# basically acts like css/cascading
	elsif (defined $self->{'ref'})
	{
		# get style from referenced block styles
		return $self->{'ref'}->styles->get($option);
	}

	# return null
	return undef;

}
# EO sub style

####################################################################################################

# get parsed css comment option by name
#**************************************************************************************************
sub option
{

	# get passed variables
	my ($self, $option) = @_;

	# do we have a valid style in current block
	if (defined $self->options->get($option))
	{
		# get style from current block styles
		return $self->options->get($option);
	}
	# maybe we have a reference block
	# basically acts like css/cascading
	elsif (defined $self->{'ref'})
	{
		# get style from referenced block styles
		return $self->{'ref'}->options->get($option);
	}

	# return null
	return undef;

}
# EO sub option

####################################################################################################
####################################################################################################
1;
