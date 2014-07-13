###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package OCBNET::Webmerge::Optimize::ANY;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################
###################################################################################################

sub path
{
	die "Hi";
}

################################################################################
use OCBNET::Webmerge qw(optimizers);
################################################################################
use OCBNET::Process qw(process);
################################################################################

sub execute
{

	my ($block) = @_;

	# run here as we do not want to take any order
	# all optimizer steps can be run in parallel jobs
	# at a certain level we will run mutliple executables
	# each <tag> knows multiple exectuables to be choosen from

	# process all optimizer types
	#foreach my $block ($node->children)
	{

		my @optimizers = optimizers($block->tag . 'opt');

		my @work;
		# process all file entries in block
		foreach my $entity ($block->children)
		{
			foreach my $file ($entity->files)
			{
				my @chain;
				foreach my $optimizer (@optimizers)
				{
					push @chain, OCBNET::Process->new($optimizer->[0], 'args' => &{$optimizer->[1]}($file)),
				}
				push @work, \@chain if scalar @chain;
			}
		}
		warn "run ", $block->tag, " with ", scalar(@work), " items\n";
		process \@work, $block->option('jobs') if scalar @work;
	}

}

sub classByTag2
{
	"OCBNET::Webmerge::Optimize::FILE";
}

###################################################################################################
###################################################################################################
1;
