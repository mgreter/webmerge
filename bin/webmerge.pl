#!/usr/bin/perl
################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################

use utf8;
use strict;
use warnings;

################################################################################
use File::Spec::Functions qw(rel2abs);
################################################################################

BEGIN
{
	# load find bin
	use FindBin qw($Bin);
	# add local  library path
	use lib rel2abs("../lib", $Bin);
}

################################################################################

# add path for local installs
# usefull when packed as an exe
BEGIN
{
	# get OS specific path delimiter
	my $PDEL = $^O eq 'MSWin32' ? ';' : ':';
	# extend the executable path for local/portable libs
	$ENV{'PATH'} = join($PDEL, "$Bin/../im", $ENV{'PATH'}) if -d "$Bin/../im";
	$ENV{'PATH'} = join($PDEL, "$Bin/../gm", $ENV{'PATH'}) if -d "$Bin/../gm";
	$ENV{'PATH'} = join($PDEL, "$Bin/../jre7", $ENV{'PATH'}) if -d "$Bin/../jre7";
	$ENV{'PATH'} = join($PDEL, "$Bin/../utils", $ENV{'PATH'}) if -d "$Bin/../utils";
	$ENV{'PATH'} = join($PDEL, "$Bin/../google", $ENV{'PATH'}) if -d "$Bin/../google";
	$ENV{'PATH'} = join($PDEL, "$Bin/../ruby/bin", $ENV{'PATH'}) if -d "$Bin/../ruby";
	$ENV{'PATH'} = join($PDEL, "$Bin/../perl/bin", $ENV{'PATH'}) if -d "$Bin/../perl";
	# set path for image magick and/or graphics magick
	$ENV{'MAGICK_HOME'} = "$Bin/../im" if -d "$Bin/../im";
	$ENV{'MAGICK_HOME'} = "$Bin/../gm" if -d "$Bin/../gm";
}

################################################################################
use OCBNET::Webmerge qw(fixIOenc);
################################################################################

# fix input output handles
# crashes watchdog on windows
# utf8 encoding seems to be the issue
# BEGIN { OCBNET::Webmerge::fixIOenc; }

# uncomment to debug any unknown error
# $SIG{__DIE__} = sub { Carp::confess @_ };

################################################################################

# load the main cmd line program
require OCBNET::Webmerge::CmdLine;

# create a new webmerge instance
my $webmerge = OCBNET::Webmerge::CmdLine->new;

# parse config and run
$webmerge->parse->run;

__END__


=head1 NAME

webmerge - Asset manager for js/css and related files

=head1 SYNOPSIS

webmerge [options] [steps]

 Options:
   -f, --configfile       main xml configuration
   -d, --doctype          how to render includes [html|xhtml|html5]
   -j, --jobs             number of jobs (commands) to run simultaneously

   -w, --watchdog         start the watchdog process (quit with ctrl+c)
   --webserver            start the webserver process (quit with ctrl+c)
   --webport              port number for the webserver to listen to

   --webroot              webroot directory to render absolute urls
   --absoluteurls         export urls as absolute urls (from webroot)

   --webdump              dump a copy of all html files (resolve SSI)
   --dumproot             directory where the dump files are written to

   --import-css           inline imported css files into stylesheet
   --import-scss          inline imported scss files into stylesheet
   --rebase-urls-in-css   adjust urls in css files to parent stylesheet
   --rebase-urls-in-scss  adjust urls to scss files to parent stylesheet
   --rebase-imports-css   adjust import urls for css files (only if not inlined)
   --rebase-imports-scss  adjust import urls for scss files (only if not inlined)

   --referer              optional referer url for external downloads
   --inlinedataexts       file extensions to inline (comma separated)
   --inlinedatamax        maximum file sizes to inline into stylesheets

   --crc-check            run crc check before exiting
   --crc-file             write crc file beside generated files
   --crc-comment          append crc comment into generated files

   --fingerprint          add fingerprints to includes (--fp)
   --fingerprint-dev      for dev context [query|directory|file] (--fp-dev)
   --fingerprint-live     for live context [query|directory|file] (--fp-live)

   --txt-type             text type [nix|mac|win]
   --txt-remove-bom       remove superfluous utf boms
   --txt-normalize-eol    normalize line endings to given type
   --txt-trim-trailing    trim trailing whitespace in text files

   --headtmpl             text to prepend to generated files
   --jsdeferer            javascript loader for defered loading
   --tmpl-embed-js        template for js embedder generator
   --tmpl-embed-php       template for php embedder generator

       --action           use to disable all actions
   -p, --prepare          enable/disable prepare blocks
   -o, --optimize         enable/disable optimizer blocks
   -m, --merge            use to disable all merge blocks
       --css              enable/disable css merge blocks
       --js               enable/disable js merge blocks
   -i, --headinc          enable/disable headinc blocks
   -e, --embedder         enable/disable embedder blocks

   -l, --level            set optimization level (0-9)

   --dev                  enable/disable dev targets
   --join                 enable/disable join targets
   --minify               enable/disable minify targets
   --compile              enable/disable compile targets
   --license              enable/disable license targets

   --optimize-txt         enable/disable optimizer for text files (--txt)
   --optimize-jpg         enable/disable optimizer for jpg images (--jpg)
   --optimize-gif         enable/disable optimizer for gif images (--gif)
   --optimize-png         enable/disable optimizer for png images (--png)
   --optimize-mng         enable/disable optimizer for mng images (--mng)
   --optimize-zip         enable/disable optimizer for zip archives (--zip)
   --optimize-gz          enable/disable optimizer for gz archive files (--gz)

   -dbg, --debug          enable/disable debug mode

   --man                  full documentation
   --opts                 list command line options
   -?, --help             brief help message with options

 Steps:
   Just process certain steps in configuration

=head1 OPTIONS

=over 8

=item B<-man>

Prints the manual page and exits.

=item B<-opts>

Print a sorted list of command line options and exits.

=item B<-help>

Print a brief help message with options and exits.

=back

=head1 DESCRIPTION

B<This program> merges and optimizes assets for front end web developement.

=cut