package OCBNET::Spritesets::Packing;

# https://github.com/jakesgordon/bin-packing/blob/master/js/packer.growing.js
# Perl implementation by marcel.greter@ocbnet.ch - same license as original

use strict;
use warnings;

sub new
{

	return bless {};

}

sub fit
{

	my ($self, $blocks) = @_;

	@{$blocks} = sort {
		($b->{'width'} > $b->{'height'} ? $b->{'width'} : $b->{'height'}) -
		($a->{'width'} > $a->{'height'} ? $a->{'width'} : $a->{'height'})
	} @{$blocks};

	my ($node, $block);

	my $len = scalar(@{$blocks});

	my $w = $len > 0 ? $blocks->[0]->{'width'} : 0;
	my $h = $len > 0 ? $blocks->[0]->{'height'} : 0;

	$self->{'root'} =
	{
		'x' => 0,
		'y' => 0,
		'width' => $w,
		'height' => $h
	};

	for (my $n = 0; $n < $len ; $n++)
	{

		my $block = $blocks->[$n];

		if ($node = $self->findNode($self->{'root'}, $block->{'width'}, $block->{'height'}))
		{
			$block->{'fit'} = $self->splitNode($node, $block->{'width'}, $block->{'height'});
		}
		else
		{
			$block->{'fit'} = $self->growNode($block->{'width'}, $block->{'height'});
		}
	}

	return 1;

};

sub findNode
{

	my ($self, $root, $w, $h) = @_;

	return $self->findNode($root->{'right'}, $w, $h) || $self->findNode($root->{'down'}, $w, $h) if $root->{'used'};

	return $root if (($w <= $root->{'width'}) && ($h <= $root->{'height'}));

	return undef;

}

sub splitNode
{

	my ($self, $node, $w, $h) = @_;

	$node->{'used'} = 1;

	$node->{'down'} =
	{
		'x' => $node->{'x'},
		'width' => $node->{'width'},
		'y' => $node->{'y'} + $h,
		'height' => $node->{'height'} - $h
	};

	$node->{'right'} = {
		'y' => $node->{'y'},
		'height' => $node->{'height'},
		'x' => $node->{'x'} + $w,
		'width' => $node->{'width'} - $w,
	};

	return $node;

}

sub growNode
{

	my ($self, $w, $h) = @_;

	my $canGrowDown = ($w <= $self->{'root'}->{'width'});
	my $canGrowRight = ($h <= $self->{'root'}->{'height'});

	# attempt to keep square-ish by growing right when height is much greater than width
	my $shouldGrowRight = $canGrowRight && ($self->{'root'}->{'height'} >= ($self->{'root'}->{'width'} + $w));
	# attempt to keep square-ish by growing down when width is much greater than height
	my $shouldGrowDown = $canGrowDown && ($self->{'root'}->{'width'} >= ($self->{'root'}->{'height'} + $h));

	return $self->growRight($w, $h) if ($shouldGrowRight);
	return $self->growDown($w, $h) if ($shouldGrowDown);
	return $self->growRight($w, $h) if ($canGrowRight);
	return $self->growDown($w, $h) if ($canGrowDown);

	# need to ensure sensible root
	# starting size to avoid this
	return undef;

}

sub growRight
{

	my ($self, $w, $h) = @_;

	$self->{'root'} =
	{
		'x' => 0,
		'y' => 0,
		'used' => 1,
		'height' => $self->{'root'}->{'height'},
		'width' => $self->{'root'}->{'width'} + $w,
		'down' => $self->{'root'},
		'right' =>
		{
			'y' => 0,
			'width' => $w,
			'height' => $self->{'root'}->{'height'},
			'x' => $self->{'root'}->{'width'}
		}
	};

	my $node = $self->findNode($self->{'root'}, $w, $h);

	return $node ? $self->splitNode($node, $w, $h) : undef;

 };

sub growDown
{

	my ($self, $w, $h) = @_;

	$self->{'root'} =
	{
		'x' => 0,
		'y' => 0,
		'used' => 1,
		'width' => $self->{'root'}->{'width'},
		'height' => $self->{'root'}->{'height'} + $h,
		'right' => $self->{'root'},
		'down' =>
		{
			'x' => 0,
			'height' => $h,
			'width' => $self->{'root'}->{'width'},
			'y' => $self->{'root'}->{'height'}
		}
	};

	my $node = $self->findNode($self->{'root'}, $w, $h);

	return $node ? $self->splitNode($node, $w, $h) : undef;

};

return 1;
