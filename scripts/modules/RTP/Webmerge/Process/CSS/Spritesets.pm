###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Process::CSS::Spritesets;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Process::CSS::Spritesets::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(spritesets); }

###################################################################################################

# load some constants
use Fcntl qw(LOCK_UN O_RDWR);

# import program runner function
use RTP::Webmerge qw(runProgram);

# load image spriteset class
use OCBNET::Spritesets::CSS::Parser;

# import webmerge IO file reader and writer
use RTP::Webmerge::IO qw(readfile writefile);

###################################################################################################

# process spritesets with additional modules
# try to keep them as standalone as possible
# ***************************************************************************************
sub spritesets
{

	# get input variables
	my ($data, $config, $output) = @_;

	use RTP::Webmerge::Path qw(dirname basename);
	my $dir = RTP::Webmerge::Path->chdir(dirname($output->{'path'}));

	# create a new ocbnet spriteset css parser object
	my $css = OCBNET::Spritesets::CSS::Parser->new($config);

	# declare writer sub
	my $writer = sub
	{

		# get input varibles
		my ($file, $blob, $written) = @_;

		# get data for atomic file handling
		my $atomic = $config->{'atomic'};

		# write out the file and get the file handle
		my $handle = writefile($file, \$blob, $atomic, 1);
		# assertion for any write errors
		die "error write $file" unless $handle;

		# create data structure to remember ...
		unless (exists $written->{'png'})
		{ $written->{'png'} = []; }
		# ... which files have been written
		push(@{$written->{'png'}}, $handle);

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
	if ($config->{'optimize'})
	{
		# call all possible optimizers
		foreach my $program (keys %{$written})
		{
			# check if this program should run or not
			next unless $config->{'optimize-' . $program};
			# close file finehandle now to flush out changes
			CORE::close($_) foreach (@{$written->{$program}});
			# fetch all temporary file paths to be optimized by next step
			my @files = map { ${*$_}{'io_atomicfile_temp'} } @{$written->{$program}};
			# call the external optimizer program on all temporary files
			runProgram($config, $program . 'opt', \@files, $program . ' sprites');
			# re-open the file handles after the optimizers have done their work
			sysopen($_, ${*$_}{'io_atomicfile_temp'}, O_RDWR) foreach (@{$written->{$program}});
		}
		# EO each program
	}
	# EO if optimize

	# return success
	return 1;

}
# EO sub dejquery

###################################################################################################

# import registered processors
use RTP::Webmerge qw(%processors);

# register the processor function
$processors{'spritesets'} = \& spritesets;

###################################################################################################
###################################################################################################
1;