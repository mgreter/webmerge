###################################################################################################
package RTP::Webmerge::Process::CSS::Spritesets;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Process::CSS::Spritesets::VERSION = "0.8.2" }

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
use OCBNET::Spritesets::CSS;

# import webmerge IO file reader and writer
use RTP::Webmerge::IO qw(readfile writefile);

###################################################################################################

# replace jquery calls with simple dollar signs
# this way we can have best code compatibility
# and still use the dollar sign when possible
sub spritesets
{

	# get input variables
	my ($data, $config, $output) = @_;

	# create a new ocbnet spriteset object
	my $css = OCBNET::Spritesets::CSS->new($config);

	# read our stylesheet data
	$css->read($data, $config->{'atomic'});

	# call write and pass writer sub
	my $written = $css->write(sub
	{

		# get input varibles
		my ($file, $blob, $written) = @_;

		# normalize filename (still needed?)
		$file =~ s/[\/\\]+/\//g;

		# get data for atomic file handling
		my $atomic = $config->{'atomic'};

		# check if file is known
		if ($atomic->{$file})
		{

			# content has changed between writes
			# what should we do in this situation?
			if (${$atomic->{$file}->[0]} ne $blob)
			{
				# strange enough this can happen with spritesets
				# the differences are very subtile, but no idea why
				die "writing same file with different content: $file\n";
			}
			else
			{
				# this is really just a warning, nothing more
				warn "writing same file more than once: $file\n";
			}
		}
		# first write on file
		else
		{
			# write out the file and get the file handle
			my $handle = writefile($file, \$blob, $atomic, 1);
			# assertion for any write errors
			die "error write $file" unless $handle;
			# create data structure to remember ...
			unless (exists $written->{'png'})
			{ $written->{'png'} = []; }
			# ... which files have been written
			push(@{$written->{'png'}}, $handle);
		}

	});
	# EO write

	# process spritesets
	# sets sprite positions
	$css->process();

	# render result stylesheet
	${$data} = $css->render;

	# check if we are optimizing
	# if so we may should optimize images
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