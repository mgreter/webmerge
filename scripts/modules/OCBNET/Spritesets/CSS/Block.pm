####################################################################################################
# a css block inside curly braces or root
####################################################################################################
package OCBNET::Spritesets::CSS::Block;
####################################################################################################

use strict;
use warnings;

####################################################################################################

use OCBNET::Spritesets::CSS::Collection;
use base 'OCBNET::Spritesets::CSS::Collection';

####################################################################################################

sub new
{

	# get class name
	# parent is optional
	my ($pckg, $parent) = @_;

	# create new object
	my $block = {

		'head' => '',
		'blocks' => [],
		'footer' => '',

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

sub render
{


	my ($block) = @_;

	my $out = $block->head;

	if (scalar(@{$block->blocks}))
	{

		$out .= "{" if $block->parent;

		$out .= $block->body;

		$out .= $block->footer;

		$out .= "}" if $block->parent;

	}

	return $out;

}

sub body
{

	my $out = '';

	my ($block) = @_;

	if ($block->{'declarations'})
	{
		$out .= join "", map
			{ sprintf "%s%s", @{$_}; }
				@{$block->{'declarations'}};
	}
	else
	{
		foreach my $child (@{$block->blocks})
		{
			$out .= $child->render
		}
	}

	return $out;

}

sub head { $_[0]->{'head'} }
sub blocks { $_[0]->{'blocks'} }
sub parent { $_[0]->{'parent'} }
sub footer { $_[0]->{'footer'} }

sub styles { $_[0]->{'styles'} }
sub options { $_[0]->{'options'} }


sub style
{

	my ($self, $option) = @_;

	# if ($self->styles->exists($option))
	if (defined $self->styles->get($option))
	{
		return $self->styles->get($option);
	}
	elsif (defined $self->{'ref'})
	{
		return $self->{'ref'}->styles->get($option);
	}
	else
	{
		return undef;
	}

}

sub option
{

	my ($self, $option) = @_;

	if ($self->options->exists($option))
	{
		return $self->options->get($option);
	}
	elsif (defined $self->{'ref'})
	{
		return $self->{'ref'}->options->get($option);
	}
	else
	{
		return undef;
	}

}

sub each
{

	my ($self, $sub) = @_;

	$sub->($self);

	foreach my $child (@{$self->blocks})
	{
		$child->each($sub);
	}

}

####################################################################################################
1;
