###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package OCBNET::Webmerge::Plugin::CSS::Spritesets;
###################################################################################################

use Carp;
use strict;
use warnings;
use File::chdir;

################################################################################
use OCBNET::Webmerge qw(optimizers);
################################################################################
use OCBNET::Process qw();
################################################################################
use OCBNET::Webmerge::IO::OUT;
################################################################################

# plugin namespace
my $ns = 'css::spritesets';

################################################################################
# alter data in-place
################################################################################
# load some constants
use Fcntl qw(LOCK_UN O_RDWR);

sub process
{

	# get arguments
	my ($file, $data) = @_;


require OCBNET::Spritesets;

	my $dir; # = RTP::Webmerge::Path->chdir(dirname($output->{'path'}));

my $config = { 'debug' => 0 };

	# change back into dirname
	local $CWD = $file->dirname;

	# create a new ocbnet spriteset css parser object
	my $css = OCBNET::Spritesets::CSS::Parser->new($config);

	# declare writer sub
	my $writer = sub
	{
		# get input varibles
		my ($path, $blob, $written) = @_;
		# create a new output file for spriteset image
		my $spriteset = OCBNET::Webmerge::IO::OUT->new;
		# set the path on the attribute
		$spriteset->{'attr'}->{'path'} = $path;
		# loosely couple the nodes together
		$spriteset->{'parent'} = $file;
		# change back into dirname
		local $CWD = $file->dirname;
		# write out the file and get the file handle
		my $handle = $spriteset->write(\$blob);
		# assertion for any write errors
		die "error write $file" unless $handle;
		# create data structure to remember ...
		unless (exists $written->{'png'})
		{ $written->{'png'} = []; }
		# ... which files have been written
		push(@{$written->{'png'}}, [$handle, $spriteset]);


	};
	# EO sub $writer

	# read stylesheet and process spritesets
	$css->read($data)->rehash->load;
	$css->optimize->distribute->finalize;
	my $written = $css->write($writer);
	${$data} = $css->process->render;

	# print debug messages if wished
	$css->debug if $config->{'debug'};

	# optimize spriteset images
	if ($config->{'optimize'} || 1)
	{
		# call all possible optimizers
		foreach my $program (keys %{$written})
		{
			# check if this program should run or not
			# next unless $config->{'optimize-' . $program};
			# close file finehandle now to flush out changes
			CORE::close($_) foreach (map { $_->[0] } @{$written->{$program}});

			# fetch all temporary file paths to be optimized by next step
			my @files = map { [ ${*{$_->[0]}}{'io_atomicfile_temp'}, $_->[1] ] } @{$written->{$program}};


my @optimizers = optimizers($program . 'opt');

		my @work;
		# process all file entries in block
			foreach my $file (@files)
			{
				my @chain;
				foreach my $optimizer (@optimizers)
				{
					use File::Basename;
					my $p = dirname $file->[1]->tpath;
					print `dir $p` unless -e $file->[1]->tpath;
					warn("not existing [", $file->[1]->tpath, "]") && sleep 10 unless -e $file->[1]->tpath;
					push @chain, OCBNET::Process->new($optimizer->[0], 'args' => &{$optimizer->[1]}($file->[1])),
				}
				push @work, \@chain if scalar @chain;
			}

		warn "run ", $program, " with ", scalar(@work), " items\n";
		OCBNET::Process::process \@work, $file->option('jobs') if scalar @work;








			# call the external optimizer program on all temporary files
	#		runProgram($config, $program . 'opt', [ map { $_->[1]->option('asd'); $_->[1] } @files ], $program . ' sprites');
			# re-open the file handles after the optimizers have done their work
			sysopen($_->[0], ${*{$_->[0]}}{'io_atomicfile_temp'}, O_RDWR) foreach (@{$written->{$program}});
		}
		# EO each program
	}
	# EO if optimize










	# module is optional
#	require OCBNET::CSS3::Minifier;

	# define options hash for minifier
#	my $options = { 'level' => $file->option('level'), 'pretty' => 0 };

	# minify via our own css minifyer
#	${$data} = OCBNET::CSS3::Minifier::minify(${$data}, $options);

	# check if minfier had any issues or errors
#	die "OCBNET::CSS3::Minifier had an error" unless defined ${data};

	# return reference
	return $data;

}
# EO process

################################################################################
# called via perl loaded
################################################################################

sub import
{
	# get arguments
	my ($fqns, $node, $webmerge) = @_;
	# register our processor to document
	$node->document->processor($ns, \&process);
}

################################################################################
################################################################################
1;