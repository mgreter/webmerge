###################################################################################################
package RTP::Webmerge::Process::CSS::Spritesets;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Process::CSS::Spritesets::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(spritesets); }

###################################################################################################

# load some constants
use Fcntl qw(LOCK_UN O_RDWR);

# import functions from IO module
use RTP::Webmerge::IO qw(readfile);

use RTP::Webmerge::IO::CSS qw($re_url wrapURL exportURI);

use RTP::Webmerge::Path qw(web_url web_path);

use RTP::Webmerge::Path qw($webroot);

use RTP::Webmerge::IO qw(writefile);

use OCBNET::Spritesets::CSS;

###################################################################################################

# replace jquery calls with simple dollar signs
# this way we can have best code compatibility
# and still use the dollar sign when possible
sub spritesets
{

	# get input variables
	my ($data, $config, $output) = @_;

	my $from = sub
	{
		my ($url) = @_;
		return $url;
	};
	my $to = sub
	{
		my ($url) = @_;
		return $url;
	};

	# parse spritesets and insert bg styles
	# ${$data} = ${ parseSpritesets($data, $from, $to, $config->{'atomic'}) };

	my $css = OCBNET::Spritesets::CSS->new();

	my $rv = 0;

	$css->read($data, $config->{'atomic'});

	my $written = $css->write(sub
	{

		my ($file, $blob, $written) = @_;

		$file =~ s/[\/\\]+/\//g;

		my $atomic = $config->{'atomic'};

			if ($atomic->{$file})
			{
				# file has already been written
				if (${$atomic->{$file}->[0]} ne $blob)
				{

					# open(my $fh1, ">", 'out1.tst');
					# open(my $fh2, ">", 'out2.tst');

					# print $fh1 ${$atomic->{$file}->[0]};
					# print $fh2 $blob;

					# die "cannot write same file with different content: $file";

					# strange enough this can happen with spritesets
					# the differences are very subtile, but no idea why
					warn "writing same file with different content: $file\n";

				}
				else
				{
					warn "writing same file more than once: $file\n";
				}
			}
			else
			{
				$file = web_path(web_url($file));

				my $handle = writefile($file, \$blob, $atomic, 1);
				die "error write $file" unless $handle;
				unless (exists $written->{'png'})
				{ $written->{'png'} = []; }
				push(@{$written->{'png'}}, $handle);
			}
	});

	# process spriteset
	# sets sprite positions
	$css->process();

	# render resulting css
	${$data} = $css->render;

# die length($$data);

	# parse spritesets and insert bg styles
	# my $rv = parseSpritesets($config, $data, $from, $to, $config->{'atomic'});

	# assign the new css code
	# ${$data} = ${$rv->[0]};

	# check if we are optimizing
	# if so we may should optimize images
	if ($config->{'optimize'})
	{
		# load function from main module
		use RTP::Webmerge qw(runProgram);
		# call all possible optimizers
		foreach my $program (keys %{$written})
		{
			# check if this program should run or not
			next unless $config->{'optimize-' . $program};

			foreach (@{$written->{$program}})
			{
				CORE::close($_);
			}

			# call the external program on all files
			runProgram($config, $program . 'opt',
			[
				map {
					# optimize the temp path
					${*$_}{'io_atomicfile_temp'}
				}
				@{$written->{$program}}
			], $program . ' sprites');

			foreach (@{$written->{$program}})
			{
				sysopen($_, ${*$_}{'io_atomicfile_temp'}, O_RDWR)
			}

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
use RTP::Webmerge qw(%processors @initers);

# register the processor function
$processors{'spritesets'} = \& spritesets;

# register initializer
push @initers, sub
{

	# get input variables
	my ($config) = @_;

	# assign default value to variable
	# $config->{'option'} = 0;

	# return additional get options attribute
	return (
		# 'option=s' => \ $config->{'option'}
	);

};
# EO plugin initer

###################################################################################################
###################################################################################################
1;