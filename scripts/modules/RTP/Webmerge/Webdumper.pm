###################################################################################################
# Copyright 2013 by Marcel Greter
# This file is part of Webmerge (GPL3)
###################################################################################################
package RTP::Webmerge::Webdumper;
###################################################################################################

use Carp;
use strict;
use warnings;

###################################################################################################

# define our version string
BEGIN { $RTP::Webmerge::Webserver::Webdumper::VERSION = "0.9.0" }

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter) }

# define our functions to be exported
BEGIN { our @EXPORT = qw(webdump); }

###################################################################################################
use RTP::Webmerge::Path;
###################################################################################################

sub webdump
{

	my ($config) = @_;

	my $webroot = check_path($config->{'webroot'});
	my $dumproot = check_path($config->{'dumproot'});

	my @files;

	my @dirs = ($webroot);

	while (my $dir = shift @dirs)
	{
 		opendir (my $dh, $dir) or die "not opendir";
		while(defined (my $item = readdir($dh)))
		{
			next if $item eq '.';
			next if $item eq '..';
			next if $item eq 'node_modules';
			my $path = join('/', $dir, $item);
			push @dirs, $path if -d $path;
			next unless $item =~ m/\.s?html?$/i;
			push @files, $path if -f $path;
		}
		closedir ($dh);
	}

	use File::Spec;
	use File::Path;
	use File::Basename;
	use LWP::MediaTypes qw(guess_media_type);

	foreach my $file (@files)
	{
		my $src = File::Spec->abs2rel( $file, $webroot );
		my $dst = File::Spec->join( $dumproot, $src);
		print "dumping ", $src, "\n";

		mkpath(dirname $dst);

		$file =~ s/\//\\/gm;
		$ENV{'DOCUMENT_ROOT'} = canonpath(check_path($config->{'webroot'}));
		$CGI::SHTML::ROOTDIR = $ENV{'DOCUMENT_ROOT'};

		chdir dirname $file;
		use Encode qw(encode decode);
		use IO::HTML qw(html_file_and_encoding);
		my ($fh, $enc, $bom) = html_file_and_encoding($file);
		my $cgi = CGI::SHTML->new;
		$fh->open($file, "r") or die "open file";
		my($ct,$ce) = guess_media_type($file);
		warn "cannot guess media type?" if ($ct ne 'text/html');
		# print "HTML with encoding charset: $enc\n" if $config->{'debug'};
		$cgi->{'debug'} = $config->{'debug'};
		my($size,$mtime) = (stat $file)[7,9];
		my $content = join('', <$fh>);
		$content = decode($enc, $content);
		$content = $cgi->parse_shtml($content);
		$content = encode($enc, $content);
		open(my $out, '>', $dst) or die "write";
		print $out $content; close $out;

		print " dumped ", $src, " -> ok\n";

	}

}

###################################################################################################
###################################################################################################
1;
