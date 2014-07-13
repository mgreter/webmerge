###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package OCBNET::Webmerge::Plugin::CSS::Spritesets;
###################################################################################################

use Carp;
use strict;
use warnings;

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

warn "====" , join("; ", @_), "\n";

	chdir $file->dirname;

	my $dir; # = RTP::Webmerge::Path->chdir(dirname($output->{'path'}));

my $config = { 'debug' => 1 };

	# create a new ocbnet spriteset css parser object
	my $css = OCBNET::Spritesets::CSS::Parser->new($config);

	# declare writer sub
	my $writer = sub
	{

		# get input varibles
		my ($file, $blob, $written) = @_;

		print "WRITE $file\n"; return 1;

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