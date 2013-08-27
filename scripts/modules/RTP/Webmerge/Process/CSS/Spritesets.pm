#!/usr/bin/perl

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
use Fcntl qw(LOCK_UN);

# import functions from IO module
use RTP::Webmerge::IO qw(readfile);

use RTP::Webmerge::IO::CSS qw($re_url wrapURL);

use OCBNET::Spritesets qw(parseSpritesets);

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

	# parse spritesets and insert bg styles
	my $rv = parseSpritesets($config, $data, $from, $to, $config->{'atomic'});

	# assign the new css code
	${$data} = ${$rv->[0]};

	# check if we are optimizing
	# if so we may should optimize images
	if ($config->{'optimize'})
	{
		# load function from main module
		use RTP::Webmerge qw(runProgram);
		# call all possible optimizers
		foreach my $program (keys %{$rv->[1]})
		{
			# check if this program should run or not
			next unless $config->{'optimize-' . $program};
			# call the external program on all files
			runProgram($config, $program . 'opt',
			[

				map {
					# sync to disk
					$_->sync;
					# releast locks
					flock($_, LOCK_UN);
					# optimize the temp path
					${*$_}{'io_atomicfile_temp'}
				}
				@{$rv->[1]->{$program}}

			], $program . ' sprites');
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
	# $config->{'inlinedatamax'} = 4096;

	# extensions to be embeded in css
	# $config->{'inlinedataexts'} = 'gif,jpg,jpeg,png';

	# return additional get options attribute
	return (
		# 'inlinedatamax=i' => \ $config->{'cmd_inlinedatamax'},
		# 'inlinedataexts=s' => \ $config->{'cmd_inlinedataexts'}
	);

};
# EO plugin initer

###################################################################################################
###################################################################################################
1;
