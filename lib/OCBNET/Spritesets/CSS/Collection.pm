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

use OCBNET::CSS::Parser::Base;
use OCBNET::CSS::Parser::Colors;

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
my %boxmodel =
(
	'margin' => 1,
	'padding' => 1,
	# not yet implemented
	# but parse them anyway
	'sprite-margin' => 1,
	'sprite-padding' => 1
);

# attributes with keywords
# and more complex logic
my %shorthand =
(
	'background' => [
		[ 'color' => $re_css_color ],
		[ 'image' => $re_css_bg_image ],
		[ 'repeat' => $re_css_bg_repeat ],
		[ 'attachment' => $re_css_bg_attachment ],
		[ 'position' => $re_css_bg_position_block ]
	]
);

####################################################################################################

# set a value by name
#**************************************************************************************************
sub set
{

	# get passed arguments
	my ($self, $name, $value, $imp) = @_;

	# hotfix to at least be able to read
	# important rules too, altough we will
	# not consider their importance really
	$imp = ($value =~ s/\s*!important\s*$//i) || $imp;

	# test if this a shorthand
	if (exists $shorthand{$name})
	{

		# get array with all shorthands
		my $shorthands = $shorthand{$name};

		# parse value completly
		while ($value ne '')
		{
			# status variable
			my $rv = 0;
			# parse in order (priority)
			foreach my $shorthand (@{$shorthands})
			{
				# get the attribute name
				my $attr = $shorthand->[0];
				# regular expression for attribute
				my $re_css_attribute = $shorthand->[1];
				# test if the current value matches
				if ($value =~ s/^\s*($re_css_attribute)\s*//)
				{
					# set the property (may be shorthand too)
					$self->set(join('-', $name, $attr), $1, $imp);
					# remember state and exit loop
					$rv = 1; last
				}
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
				$self->set(join('-', $name, 'x'), $2, $imp);
				$self->set(join('-', $name, 'y'), $1, $imp);
			}
			else
			{
				$self->set(join('-', $name, 'x'), $1, $imp);
				$self->set(join('-', $name, 'y'), $2, $imp);
			}
		}

		# one value means the other is centered
		if ($value =~ m/\A\s*
			($re_css_bg_position)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'x'), $1, $imp);
			$self->set(join('-', $name, 'y'), '50%', $imp);
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
			$self->set(join('-', $name, 'x'), $1, $imp);
			$self->set(join('-', $name, 'y'), $2, $imp);
		}

		# only adjust one axis
		if ($value =~ m/\A\s*
			($re_css_length|inherit)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'x'), $1, $imp);
			$self->set(join('-', $name, 'y'), '100%', $imp);
		}

	}
	# EO if 'background-size'

	# do not inherit for all axes
	elsif ($name eq 'sprite')
	{
		$value =~ m/^\s*($re_css_name)\s+($re_css_url)\s*(\!important)?$/i;
		# split the shorthand value into id and url
		my ($id, $url) = split(/\s+/, $value, 2);
		# set the block options for this sprite
		$self->set('css-id', $1) if defined $1;
		$self->set('sprite-image', $2) if defined $2;
		$self->set('sprite-importance', $3) if defined $3;
	}

	# parse margin and padding boxmodel
	elsif (exists $boxmodel{$name})
	{

		if ($value =~ m/\A\s*
			($re_css_length)\s*
			($re_css_length)\s*
			($re_css_length)\s*
			($re_css_length)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'top'), $1, $imp);
			$self->set(join('-', $name, 'left'), $4, $imp);
			$self->set(join('-', $name, 'right'), $2, $imp);
			$self->set(join('-', $name, 'bottom'), $3, $imp);
		}

		if ($value =~ m/\A\s*
			($re_css_length)\s*
			($re_css_length)\s*
			($re_css_length)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'top'), $1, $imp);
			$self->set(join('-', $name, 'left'), $2, $imp);
			$self->set(join('-', $name, 'right'), $2, $imp);
			$self->set(join('-', $name, 'bottom'), $3, $imp);
		}

		if ($value =~ m/\A\s*
			($re_css_length)\s*
			($re_css_length)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'top'), $1, $imp);
			$self->set(join('-', $name, 'left'), $2, $imp);
			$self->set(join('-', $name, 'right'), $2, $imp);
			$self->set(join('-', $name, 'bottom'), $1, $imp);
		}

		if ($value =~ m/\A\s*
			($re_css_length)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'top'), $1, $imp);
			$self->set(join('-', $name, 'left'), $1, $imp);
			$self->set(join('-', $name, 'right'), $1, $imp);
			$self->set(join('-', $name, 'bottom'), $1, $imp);
		}

	}
	# EO boxmodel

	# just assign the value
	# ignore if we don't understand
	# implement atrributes when needed
	else
	{
		unless ($imp) { $self->{$name} = $value; }
		else { $self->{ '!' . $name } = $value; }
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

	# try to fetch important rule first
	# only if we are not yet asking for it
	unless ($name =~ m/^\!/)
	{
		# prepend a exlamation mark to the name
		my $value = $self->get('!' . $name);
		# return the important value if given
		return $value if defined $value;
	}

	# return combined shorthand
	if ($name eq 'background-position')
	{
		return join(' ',
			$self->get('background-position-x'),
			$self->get('background-position-y')
		);
	}
	# return boolean if we are repeating
	elsif ($name eq 'background-repeat-x')
	{
		return (not defined $self->{'_parent'}->style('background-repeat')) ||
			$self->get('background-repeat') =~ m/repeat-x/i ? 1 : 0;
	}
	# return boolean if we are repeating
	elsif ($name eq 'background-repeat-y')
	{
		return (not defined $self->{'_parent'}->style('background-repeat')) ||
			$self->get('background-repeat') =~ m/repeat-y/i ? 1 : 0;
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