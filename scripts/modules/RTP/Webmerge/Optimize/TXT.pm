#!/usr/bin/perl

###################################################################################################
package RTP::Webmerge::Optimize::TXT;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Optimize::TXT::VERSION = "0.70" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(cleantxt); }

###################################################################################################

# safe text cleaning
# for html, css and js
# changes source files
sub cleantxt
{

	# get input variables
	my ($data) = @_;

	# trim trailing whitespace
	${$data} =~ s/(?:\s|\t)+$//g;

	# remove unwanted utf8 boms
	${$data} =~ s/^\xEF\xBB\xBF//;

	# convert newlines from mac/win to unix
	${$data} =~ s/(?:\r\n|\n\r)/\n/g;

	# return success
	return 1;

}
# EO sub cleantxt

###################################################################################################

# load webmberge module variables to hook into
use RTP::Webmerge qw(@initers @checkers %executables);

# load functions from webmerge io library
use RTP::Webmerge::IO qw(processfile);

###################################################################################################

# push to initers
# return for getOpts
push @initers, sub
{

	# get config
	my ($config) = @_;

	# create config variable to be available
	$config->{'cmd_optimize-txt'} = 1;

	# connect each tmpl variable with the getOpt option
	return ('optimize-txt|txt!', \ $config->{'cmd_optimize-txt'});

};
# EO push initer

###################################################################################################

# push to checkers
push @checkers, sub
{

	# get config
	my ($config) = @_;

	# disable if not optimizing
	unless ($config->{'optimize'})
	{ $config->{'optimize-txt'} = 0; }

	# do nothing if feature is disabled
	return unless $config->{'optimize-txt'};

	# define executables to optimize txts
	$executables{'txtopt'} = ['txtopt', sub {

		# process that file via cleantxt
		return processfile($_[0], \&cleantxt);

	}];

};
# EO push checker

###################################################################################################

# now create a new file optimizer subroutine and hook it into our optimizers
$RTP::Webmerge::Optimize::optimizer{'txt'} = RTP::Webmerge::Optimize::fileOptimizer('txt');

###################################################################################################
###################################################################################################
1;
