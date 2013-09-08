###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
####################################################################################################
# this block stacks the sprites vertically
# or horizontally together (and aligned)
####################################################################################################
package OCBNET::Spritesets::Sprite;
####################################################################################################

use strict;
use warnings;

####################################################################################################

use base 'OCBNET::Spritesets::Block';

####################################################################################################

# use File::Slurp;
# use Image::Magick;

use File::Spec qw(rel2abs);

sub debug
{

	# get our object
	my ($self) = @_;

	# debug filename
	return sprintf(
		'%s %s',
		substr(File::Spec->abs2rel( $self->{'filename'}, '.' ), - 16),
		$self->SUPER::debug
	);

}

####################################################################################################

sub new
{

	# shift class name
	my $pkg = shift;

	# define initial hash
	my $self = {

		# stack position
		'x' => undef,
		'y' => undef,
		'filename' => undef,
		# imagemagick object
		'image' => undef,
		# sprite dimensions
		'width' => undef,
		'height' => undef,
		# scale factors
		'scale-y' => 1,
		'scale-x' => 1,
		# background sizing
		'size-y' => undef,
		'size-x' => undef,
		# background repeating
		'repeat-y' => 0,
		'repeat-x' => 0,
		# is sprite enclosed
		'enclosed-x' => 0,
		'enclosed-y' => 0,
		# background position
		'position-y' => 'top',
		'position-x' => 'left',
		# background margins
		# 'margin-top' => 0,
		# 'margin-left' => 0,
		# 'margin-right' => 0,
		# 'margin-bottom' => 0,
		# background paddings
		'padding-top' => 0,
		'padding-left' => 0,
		'padding-right' => 0,
		'padding-bottom' => 0

	};

	%{$self} = (%{$self}, %{$_[0]});

	if ($self->{'debug'})
	{
		eval
		{
			no warnings 'uninitialized';
			my $data = join('', values %{$self});
			use warnings 'uninitialized';
			use Digest::MD5 qw(md5_hex);
			my $digest = md5_hex($data);
			$self->{'bg'} = sprintf
				'xc:rgba(%d, %d, %d, 0.25)',
					hex(substr($digest, 0, 2)),
					hex(substr($digest, 4, 2)),
					hex(substr($digest, 6, 2));
		}
	}

	# my $image = new Image::Magick;
	my $image = new Graphics::Magick;

	if ($self->{'filename'})
	{
		my $err = $image->Read($self->{'filename'});
		die "Error from GraphicsMagick:\n", $err if $err;
		$self->{'w'} = $image->Get('width');
		$self->{'h'} = $image->Get('height');
		$self->{'width'} = $image->Get('width');
		$self->{'height'} = $image->Get('height');
		# printf "readed %s (%d/%d)\n", $self->{'filename'}, $self->{'width'}, $self->{'height'};
	}

	if ($self->{'width'} && $self->{'size-x'})
	{
		my $width = $self->{'width'};
		my $size = $self->{'size-x'};
		$self->{'scale-x'} = $width / $size;
		unless ($self->{'scale-x'} =~ m/^\d+$/)
		{
			warn sprintf "Illegal sprite: %s\n", $self->{'filename'};
			warn sprintf "Scale not valid: %s\n", $self->{'scale-x'};
			warn sprintf "Background X Dimension: %s\n", $size;
			warn sprintf "Sprite X Resolution: %s\n", $width;
			Carp::confess "Abort, Fatal Error";
		}
	}

	if ($self->{'height'} && $self->{'size-y'})
	{
		my $height = $self->{'height'};
		my $size = $self->{'size-y'};
		$self->{'scale-y'} = $height / $size;
		unless ($self->{'scale-y'} =~ m/^\d+$/)
		{
			warn sprintf "Illegal sprite: %s\n", $self->{'filename'};
			warn sprintf "Scale not valid: %s\n", $self->{'scale-y'};
			warn sprintf "Background Y Dimension: %s\n", $size;
			warn sprintf "Sprite Y Resolution: %s\n", $height;
			Carp::confess "Abort, Fatal Error";
		}
	}

	$self->{'image'} = $image;

	$self = bless $self, $pkg;

	if ($self->{'bg'})
	{
		# my $bg = new Image::Magick;
		my $bg = new Graphics::Magick;
		$bg->Set(size => $self->size);
		$bg->Set(quality => 3);
		$bg->ReadImage($self->{'bg'});
		$bg->Quantize(colorspace=>'RGB');
		$self->{'img-bg'} = $bg;
	}

	return $self;

}

sub isFixedX { $_[0]->{'enclosed-x'} }
sub isFixedY { $_[0]->{'enclosed-y'} }
sub isRepeatX { $_[0]->{'repeat-x'} }
sub isRepeatY { $_[0]->{'repeat-y'} }

sub notFixedX { not $_[0]->{'enclosed-x'} }
sub notFixedY { not $_[0]->{'enclosed-y'} }
sub notRepeatX { not $_[0]->{'repeat-x'} }
sub notRepeatY { not $_[0]->{'repeat-y'} }

sub isFlexibleX { not $_[0]->{'enclosed-x'} }
sub isFlexibleY { not $_[0]->{'enclosed-y'} }

sub isFixed { $_[0]->{'enclosed-x'} || $_[0]->{'enclosed-y'} }
sub notFixed { not ($_[0]->{'enclosed-x'} || $_[0]->{'enclosed-y'}) }
sub isFixedBoth { $_[0]->{'enclosed-x'} && $_[0]->{'enclosed-y'} }
sub notFixedBoth { not ($_[0]->{'enclosed-x'} && $_[0]->{'enclosed-y'}) }

sub isFlexible { not ($_[0]->{'enclosed-x'} && $_[0]->{'enclosed-y'}) }
sub notFlexible { $_[0]->{'enclosed-x'} && $_[0]->{'enclosed-y'} }
sub isFlexibleBoth { not ($_[0]->{'enclosed-x'} || $_[0]->{'enclosed-y'}) }
sub notFlexibleBoth { $_[0]->{'enclosed-x'} || $_[0]->{'enclosed-y'} }

sub isRight { (not defined $_[0]->{'position-x'}) || $_[0]->{'position-x'} =~ m/^right$/i; }
sub isBottom { (not defined $_[0]->{'position-y'}) || $_[0]->{'position-y'} =~ m/^bottom$/i; }
sub notRight { not((not defined $_[0]->{'position-x'}) || $_[0]->{'position-x'} =~ m/^right$/i); }
sub notBottom { not((not defined $_[0]->{'position-y'}) || $_[0]->{'position-y'} =~ m/^bottom$/i); }

sub isRepeatBoth { $_[0]->{'repeat-x'} && $_[0]->{'repeat-y'} }
sub notRepeatBoth { not ($_[0]->{'repeat-x'} && $_[0]->{'repeat-y'}) }

sub isRepeating { $_[0]->{'repeat-x'} || $_[0]->{'repeat-y'} }
sub isRepeatingBoth { $_[0]->{'repeat-x'} && $_[0]->{'repeat-y'} }

sub notRepeating { not ($_[0]->{'repeat-x'} || $_[0]->{'repeat-y'}) }
sub notRepeatingBoth { not ($_[0]->{'repeat-x'} && $_[0]->{'repeat-y'}) }

sub getPosition
{

	my ($self) = @_;

	my $x = $self->{'fit'}->{'x'} || $self->{'x'};
	my $y = $self->{'fit'}->{'y'} || $self->{'y'};

	if ($self->{'parent'})
	{
		my $position = $self->{'parent'}->getPosition();
		$x += $position->{'x'}; $y += $position->{'y'};
	}

	return {
		'x' => $x,
		'y' => $y
	};

}

sub generate { }

sub scaleY { $_[0]->{'scale-y'} || 1; }
sub scaleX { $_[0]->{'scale-x'} || 1; }

1;
