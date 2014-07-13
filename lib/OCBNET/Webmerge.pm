################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge;
################################################################################

use strict;
use warnings;

################################################################################

require OCBNET::IO::File::JS;
require OCBNET::IO::File::CSS;
require OCBNET::IO::File::TXT;
require OCBNET::IO::File::BIN;
require OCBNET::IO::File::HTML;

################################################################################

# declare for exporter
our (@EXPORT, @EXPORT_OK);

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { @EXPORT = qw(options isset notset ison isoff); }

# define our functions that can be exported
BEGIN { @EXPORT_OK = qw(range fixIOenc %longopts %defaults %values); }

################################################################################
# sniff encoding for output in console
################################################################################

sub fixIOenc ()
{

	# console encoding
	my $enc = ':utf8';

	# encoding on windows
	$^O eq "MSWin32" && eval
	{
		# current codepage
		my $chcp = `chcp`;
		# check for valid result
		if ($chcp =~ m /: (\d+)/)
		{ $enc = sprintf  'cp%s', $1 }
	};

	# map utf codepages from windows
	$enc = 'utf8' if $enc eq 'cp65001';
	$enc = 'utf16' if $enc eq 'cp10000';

	# setup codepage for output encoding
	binmode(STDOUT => sprintf ':encoding(%s)', $enc);
	binmode(STDERR => sprintf ':encoding(%s)', $enc);

}

################################################################################
################################################################################

sub range
{

	my ($value, $from, $to, $max) = @_;

	my $val = int(($to - $from) / 9 * $value + $from + 0.5);

	return $val < $max ? $val : $max;

}

################################################################################
# some helper functions
################################################################################

# remove unwanted object from arguments
# ******************************************************************************
my $static = sub { shift if UNIVERSAL::isa($_[0], __PACKAGE__) };

# check if the variable has something usefull set
# ******************************************************************************
sub isset ($) { &{$static}; defined $_[0] && $_[0] ne '' }
sub notset ($) { &{$static}; ! defined $_[0] || $_[0] eq '' }

# check if the variable explicitly defines a state
# ******************************************************************************
sub ison ($) { &{$static}; defined $_[0] && $_[0] =~ m/^\s*(?:on|tr|en|1)/i ? -1 : 0 }
sub isoff ($) { &{$static}; defined $_[0] && $_[0] =~ m/^\s*(?:of|fa|di|0)/i ? -1 : 0 }

################################################################################
our (%longopts, %defaults, %values);
################################################################################

sub options
{
	$defaults{$_[0]} = $_[2];
	# second argument is optional
	$longopts{$_[0]} = $_[0] . $_[1];
}

################################################################################
our (%optimizers);
################################################################################
BEGIN { push @EXPORT, qw(optimizers) }
################################################################################

# load 3rd party module
use File::Which qw(which);

# override core glob (case insensitive)
use File::Glob qw(:globally :nocase bsd_glob);

################################################################################

sub optimizers
{

	# get input arguments
	my ($key, $exe, $args, $quality) = @_;

	if (scalar(@_) >= 2)
	{
		# remove optional suffix
		$exe =~ s/\[[a-zA-Z]+\]$//;
		# glob finds the executable
		my @files = which($exe) || bsd_glob($exe);
		# assertion that we get what we actually expected
		die "strange: have multiple answers" if scalar @files > 1;
		# test if we have a valid result that exists and is executable
		$exe = undef unless scalar @files == 1 && -e $files[0] && -x _ && ! -d _;
		die "not found $a" unless $exe;
		# add the result to the optimizers array by key
		push @{$optimizers{$key}}, [$exe, $args, $quality];
	}
	elsif ($optimizers{$key})
	{
		# query for key
		@{$optimizers{$key}};
	}
	else
	{
		# abort with an error message
		warn "no optimizer for <$key>\n";
		# empty list
		();
	}

}

################################################################################
# export directory delimiter
################################################################################
BEGIN { push @EXPORT, qw(EOD) }
################################################################################
use constant EOD => $^O eq 'MSWin32' ? '\\' : '/';
################################################################################

################################################################################
# load a module by given string
# fails if used directly with require
################################################################################
BEGIN { push @EXPORT, qw(loadmodule) }
################################################################################

sub loadmodule
{
	foreach my $modname (@_)
	{
		$modname =~ s/\:\:/EOD/eg;
		require join '.', $modname, 'pm';
	}
}

################################################################################
# load additional modules
################################################################################

# require OCBNET::Webmerge::Input;
# require OCBNET::Webmerge::Output;

#require OCBNET::Webmerge::Config;
#require OCBNET::Webmerge::Optimize;

require OCBNET::Webmerge::Action::Copy;
require OCBNET::Webmerge::Action::Mkdir;

################################################################################
use File::Spec::Functions qw(abs2rel rel2abs);
################################################################################

sub dpath ($$)
{

	substr(abs2rel($_[0], $_[1]), -60);

}

################################################################################

options('debug', '|d', 0);

################################################################################
################################################################################
1;
