####################################################################################################
# this is a block where all sprites get fitted in
# the smallest available space (see packaging)
####################################################################################################
package OCBNET::Spritesets::CSS::Collection;
####################################################################################################

use strict;
use warnings;

####################################################################################################

use OCBNET::Spritesets::CSS::Base;
use OCBNET::Spritesets::CSS::Colors;

####################################################################################################


#**************************************************************************************************
our $re_css_length = qr/\b$re_number(?:em|ex|px|\%|in|cm|mm|pt|pc)?(?=\s|\b|\Z|;|,)/i;

# regular expression to match any url
#**************************************************************************************************
my $re_css_url = qr/url\((?:\'$re_apo\'|\"$re_quot\"|[^\)]*)\)/;

# regular expression for background options
#**************************************************************************************************
my $re_css_bg_image = qr/(?:none|$re_css_url|inherit)/i;
my $re_css_bg_attachment = qr/(?:scroll|fixed|inherit)/i;
my $re_css_bg_repeat = qr/(?:no-repeat|repeat|repeat-x|repeat-y|inherit)/i;
my $re_css_bg_position = qr/(?:left|right|top|bottom|center|$re_css_length|inherit)/i;

# regular expression for combine background options
#**************************************************************************************************
my $re_css_bg_position_block = qr/($re_css_bg_position(?:\s+($re_css_bg_position))?)/;


#**************************************************************************************************

my $re_css_bg = qr/(?:$re_css_bg_image|){1,5}/;


my $boxsides = {
	'margin' => 1,
	'padding' => 1,
	'sprite-padding' => 1,
};

my $constructed = {

	'background' => {
		'color' => $re_css_color,
		'image' => $re_css_bg_image,
		'repeat' => $re_css_bg_repeat,
		'attachment' => $re_css_bg_attachment,
		'position' => $re_css_bg_position_block
	}

};

sub keys
{

	return CORE::keys %{$_[0]}

}

sub set
{

	my ($self, $name, $value) = @_;

	if (exists $constructed->{$name})
	{

		$self->{$name} = 1;

		my $attributes = $constructed->{$name};

		while ($value ne '')
		{
			my $rv = 0;
			foreach my $attr (CORE::keys %{$attributes})
			{
				my $re_css_attribute = $attributes->{$attr};
				if ($value =~ s/^\s*($re_css_attribute)\s*//)
				{ $self->set(join('-', $name, $attr), $1); $rv = 1; last }
			}
			warn "invalid options for $name: ", $value && last if $rv == 0;
		}


	}
	elsif ($name eq 'background-position')
	{

		if ($value =~ m/\A\s*
			($re_css_bg_position)\s*
			($re_css_bg_position)\s*
		\z/gmx
		)
		{
			if (
			   	(($1 eq 'top' || $1 eq 'bottom') && not ($2 eq 'top' || $2 eq 'bottom'))
			 ||	(($2 eq 'left' || $2 eq 'right') && not ($1 eq 'left' || $1 eq 'right'))
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

		if ($value =~ m/\A\s*
			($re_css_bg_position)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'x'), $1);
			$self->set(join('-', $name, 'y'), '50%');
		}

	}

	elsif ($name eq 'background-size')
	{

		if ($value =~ m/\A\s*
			($re_css_length|inherit)\s*
			($re_css_length|inherit)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'x'), $1);
			$self->set(join('-', $name, 'y'), $2);
		}

		if ($value =~ m/\A\s*
			($re_css_length|inherit)\s*
		\z/gmx
		)
		{
			$self->set(join('-', $name, 'x'), $1);
			$self->set(join('-', $name, 'y'), '100%');
		}

	}

	elsif (exists $boxsides->{$name})
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
	# EO four length
	else
	{

		# print "setting: ", $name, " - ", $value, "\n";

		$self->{$name} = $value;

	}


}

sub get
{

	my ($self, $name) = @_;

	if ($name eq 'background-position')
	{
		return join(' ',
			$self->{'background-position-x'},
			$self->{'background-position-y'}
		);
	}
	elsif ($name eq 'background-repeat-x')
	{
		return (not defined $self->get('background-repeat')) ||
			$self->get('background-repeat') eq 'repeat-x' ? 1 : 0;
	}
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

	return $self->{$name};

}

sub new
{

	my ($pckg) = @_;

	my $self = {
	};

	return bless $self, $pckg;

}


sub defined
{
	my ($self, $name) = @_;
	return CORE::defined $self->{$name};
}

sub exists
{
	my ($self, $name) = @_;
	return CORE::exists $self->{$name};
}

1;