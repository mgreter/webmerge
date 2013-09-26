###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# TODO: Move bits to separated packages
####################################################################################################
package OCBNET::Spritesets::CSS::Collection;
####################################################################################################

use strict;
use warnings;

####################################################################################################

use OCBNET::Spritesets::CSS::Parser::Base;
use OCBNET::Spritesets::CSS::Parser::Colors;

####################################################################################################

# regular expression to match any url
#**************************************************************************************************
my $re_css_url = qr/url\((?:\'$re_apo\'|\"$re_quot\"|[^\)]*)\)/;

# regular expression to match any length property
#**************************************************************************************************
our $re_css_length = qr/\b$re_number(?:em|ex|px|\%|in|cm|mm|pt|pc)?(?=\s|\b|\Z|;|,)/i;

# regular expression for background options
#**************************************************************************************************
my $re_css_bg_image = qr/(?:none|$re_css_url|inherit)/i;
my $re_css_bg_attachment = qr/(?:scroll|fixed|inherit)/i;
my $re_css_bg_repeat = qr/(?:no-repeat|repeat|repeat-x|repeat-y|inherit)/i;
my $re_css_bg_position = qr/(?:left|right|top|bottom|center|$re_css_length|inherit)/i;

# regular expression for combined background options
#**************************************************************************************************
my $re_css_bg_position_block = qr/($re_css_bg_position(?:\s+($re_css_bg_position))?)/;

####################################################################################################

# attributes for box model that
# have left/top and right/bottom
my $boxmodel =
{
	'margin' => 1,
	'padding' => 1,
	# not yet implemented
	# but parse them anyway
	'sprite-margin' => 1,
	'sprite-padding' => 1,
};

# attributes with keywords
# and more complex logic
my $constructed =
{
	'background' => {
		'color' => $re_css_color,
		'image' => $re_css_bg_image,
		'repeat' => $re_css_bg_repeat,
		'attachment' => $re_css_bg_attachment,
		'position' => $re_css_bg_position_block
	}
};

####################################################################################################

sub set
{

	# get passed arguments
	my ($self, $name, $value) = @_;

	# test if this a shorthand
	if (exists $constructed->{$name})
	{

		$self->{$name} = 1;

		# get array with all shorthands
		my $attributes = $constructed->{$name};

		# parse value completly
		while ($value ne '')
		{
			# status variable
			my $rv = 0;
			# parse in order (priority)
			foreach my $attr (CORE::keys %{$attributes})
			{
				my $re_css_attribute = $attributes->{$attr};
				# test if the current value matches
				if ($value =~ s/^\s*($re_css_attribute)\s*//)
				{ $self->set(join('-', $name, $attr), $1); $rv = 1; last }
				# EO if match
			}
			# EO each shorthand

			# warn and exit loop if nothing was parsed (syntax error)
			warn "invalid options for $name: ", $value && last if $rv == 0;

		}
		# EO parse value

	}
	# EO if shorthand

	# special case top/left and right/bottom
	elsif ($name eq 'background-position')
	{

		# parse both values and correct wrong
		# order of left/top and right/bottom
		if ($value =~ m/\A\s*
			($re_css_bg_position)\s*
			($re_css_bg_position)\s*
		\z/gmx
		)
		{
			if (
			    (($1 eq 'top' || $1 eq 'bottom') && not ($2 eq 'top' || $2 eq 'bottom'))
			 || (($2 eq 'left' || $2 eq 'right') && not ($1 eq 'left' || $1 eq 'right'))
			)
			{
				$self->set(join('-', $name, 'x'), $2);
				$self->set(join('-', $name, 'y'), $1);
			}
			else
			{
				$self->set(join('-', $name, 'x'), $1);
				$self->set(join('-', $name, 'y'), $2);
			}
		}

		# one value means the other is centered
		if ($value =~ m/\A\s*
			($re_css_bg_position)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'x'), $1);
			$self->set(join('-', $name, 'y'), '50%');
		}

	}
	# EO if 'background-position'

	# do not inherit for all axes
	elsif ($name eq 'background-size')
	{

		# values are always in order
		if ($value =~ m/\A\s*
			($re_css_length|inherit)\s*
			($re_css_length|inherit)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'x'), $1);
			$self->set(join('-', $name, 'y'), $2);
		}

		# only adjust one axis
		if ($value =~ m/\A\s*
			($re_css_length|inherit)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'x'), $1);
			$self->set(join('-', $name, 'y'), '100%');
		}

	}
	# EO if 'background-size'

	# parse margin and padding boxmodel
	elsif (exists $boxmodel->{$name})
	{

		if ($value =~ m/\A\s*
			($re_css_length)\s*
			($re_css_length)\s*
			($re_css_length)\s*
			($re_css_length)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'top'), $1);
			$self->set(join('-', $name, 'left'), $4);
			$self->set(join('-', $name, 'right'), $2);
			$self->set(join('-', $name, 'bottom'), $3);
		}

		if ($value =~ m/\A\s*
			($re_css_length)\s*
			($re_css_length)\s*
			($re_css_length)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'top'), $1);
			$self->set(join('-', $name, 'left'), $2);
			$self->set(join('-', $name, 'right'), $2);
			$self->set(join('-', $name, 'bottom'), $3);
		}

		if ($value =~ m/\A\s*
			($re_css_length)\s*
			($re_css_length)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'top'), $1);
			$self->set(join('-', $name, 'left'), $2);
			$self->set(join('-', $name, 'right'), $2);
			$self->set(join('-', $name, 'bottom'), $1);
		}

		if ($value =~ m/\A\s*
			($re_css_length)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'top'), $1);
			$self->set(join('-', $name, 'left'), $1);
			$self->set(join('-', $name, 'right'), $1);
			$self->set(join('-', $name, 'bottom'), $1);
		}

	}
	# EO boxmodel

	# just assign the value
	# ignore if we don't understand
	# implement atrributes when needed
	else
	{
		$self->{$name} = $value;
	}

}
# EO sub set

####################################################################################################

# get a value by name
#**************************************************************************************************
sub get
{

	# get passed arguments
	my ($self, $name) = @_;

	# return combined shorthand
	if ($name eq 'background-position')
	{
		return join(' ',
			$self->{'background-position-x'},
			$self->{'background-position-y'}
		);
	}
	# return boolean if we are repeating
	elsif ($name eq 'background-repeat-x')
	{
		return (not defined $self->get('background-repeat')) ||
			$self->get('background-repeat') eq 'repeat-x' ? 1 : 0;
	}
	# return boolean if we are repeating
	elsif ($name eq 'background-repeat-y')
	{
		return (not defined $self->get('background-repeat')) ||
			$self->get('background-repeat') eq 'repeat-y' ? 1 : 0;
	}
	elsif ($name eq 'background-enclosed-x')
	{
		return $self->defined('width') ? 1 : 0;
	}
	elsif ($name eq 'background-enclosed-y')
	{
		return $self->defined('height') ? 1 : 0;
	}

	# return stored value
	return $self->{$name};

}
# EO sub get

####################################################################################################

# simple core methods for hash
sub new { bless {}, $_[0]; }
sub keys { CORE::keys %{$_[0]} }
sub exists { CORE::exists $_[0]->{$_[1]}; }
sub defined { CORE::defined $_[0]->{$_[1]}; }

####################################################################################################
####################################################################################################
1;