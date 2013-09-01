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
sub cleantxt ($$;$)
{

	# get input variables
	my ($data, $config, $options) = @_;

	# options are really optional
	$options = {} unless $options;

	# defined end of line characters
	# only auto switch between win and linux
	my $eol = $^O eq "MSWin32" ? "\r\n" : "\n";

	# get the end of line type
	my $type = $options->{'type'}
	         || $config->{'txt-type'}
	         || 'auto';

	# check for other forced types
	$eol = "\r\n" if $type =~ m/w/i; # win
	$eol = "\r" if $type =~ m/c/i; # mac
	$eol = "\n" if $type =~ m/x/i; # nix

	# remove unwanted utf8 boms
	if ($config->{'txt-remove-bom'})
	{ ${$data} =~ s/^\xEF\xBB\xBF//; }

	# trim trailing whitespace
	if ($config->{'txt-trim-trailing'})
	{ ${$data} =~ s/[ \f\t]+(?=[\n\r])//gm; }

	# convert newlines to desired type
	if ($config->{'txt-normalize-eol'})
	{ ${$data} =~ s/(?:\r\n|\n\r|\n|\r)/$eol/gm; }

	# return success
	return 1;

}
# EO sub cleantxt

###################################################################################################

# load webmberge module variables to hook
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

	# text file type [nix|mac|win]
	$config->{'cmd_txt-type'} = 1;
	# remove superfluous utf boms
	$config->{'cmd_txt-remove-bom'} = 1;
	# normalize line endings to given type
	$config->{'cmd_txt-normalize-eol'} = 1;
	# trim trailing whitespace in text files
	$config->{'cmd_txt-trim-trailing'} = 1;

	# connect each tmpl variable with the getOpt option
	return (
		'optimize-txt|txt!', \ $config->{'cmd_optimize-txt'},
		'txt-type=s', \ $config->{'cmd_txt-type'},
		'txt-remove-bom!', \ $config->{'cmd_txt-remove-bom'},
		'txt-normalize-eol!', \ $config->{'cmd_txt-normalize-eol'},
		'txt-trim-trailing!', \ $config->{'cmd_txt-trim-trailing'},
	);

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

	# define executables to optimize txts
	$executables{'txtopt'} = ['txtopt', sub {

		# process that file via cleantxt (pass options)
		return processfile($_[0], \&cleantxt, $_[1], $_[2]);

	}, 1];

};
# EO push checker

###################################################################################################

# now create a new file optimizer subroutine and hook it  our optimizers
$RTP::Webmerge::Optimize::optimizer{'txt'} = RTP::Webmerge::Optimize::fileOptimizer('txt');

###################################################################################################
###################################################################################################
1;