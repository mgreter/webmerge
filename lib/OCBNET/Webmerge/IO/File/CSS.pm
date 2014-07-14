################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::IO::File::CSS;
################################################################################
use base qw(OCBNET::Webmerge::IO::File::CSS::Embed);
use base qw(OCBNET::Webmerge::IO::File::CSS::Sheet);
use base qw(OCBNET::Webmerge::IO::File::CSS::Import);
use base qw(OCBNET::Webmerge::IO::File::CSS::Export);
################################################################################
use base qw(OCBNET::Webmerge::IO::Mixin::SourceMap);
################################################################################
use base qw(OCBNET::Webmerge::IO::File::TXT);
################################################################################

use strict;
use warnings;

################################################################################
use OCBNET::Webmerge qw(options);
################################################################################

options('absoluteurls', '!', 0);
options('rebase-urls-in-css', '!', 1);
options('rebase-urls-in-scss', '!', 0);
options('rebase-urls-in-sass', '!', 0);

################################################################################
# implement basedir conditionally
################################################################################
use File::Basename qw();
################################################################################

sub basedir
{
	# get arguments
	my ($node) = shift;
	# get file extension
	my $ext = $node->ext;
	# get base rebase option (default)
	my $rebase = $node->option('rebase-urls-in-css');
	# check extension specific options
	$rebase = $node->option('rebase-urls-in-scss') if $ext eq 'scss';
	$rebase = $node->option('rebase-urls-in-sass') if $ext eq 'sass';
	# conditionally handle rebase directory
	unless ($rebase) { $node->SUPER::basedir(@_) }
	else { File::Basename::dirname $node->path(@_); }
}


################################################################################
# define import template for css
################################################################################

# define the template for the style includes
# don't care about doctype versions, dev only
our $css_include_tmpl = '@import url(\'%s\');' . "\n";

################################################################################
# generate a css include (@import)
# add support for data or reference id
################################################################################

sub include
{

	# get arguments
	my ($input, $output) = @_;

	# get a unique path with added fingerprint
	# is guess target is always dev here, or is it?
	my $path = $input->fingerprint($output->target);

	# return the script include string
	return sprintf($css_include_tmpl, $path);

}

################################################################################
################################################################################

sub read
{

	# get the content from parent class
	my $content = $_[0]->SUPER::read;
die "whasads" unless (${$content} =~ m/(?:;|\n)\s*\Z/);
	${$content} .= ";\n" unless (${$content} =~ m/(?:;|\n)\s*\Z/);

	return $content;
}

################################################################################

sub ftype { 'css' }

################################################################################
################################################################################
__DATA__
1;

# obsolete?
sub finalizer
{

	# get arguments
	my ($output, $data) = @_;

	# call export on parent class
	$output->import($data);

	# get new export base dir
	my $base = $output->directory;

	# alter all urls to paths relative to the base directory
	${$data} =~ s/($re_url)/wrapUrl(exportUrl(fromUrl($1), $base, 1))/ge;

}

1;
__DATA__

################################################################################
# object mixin initialisation
################################################################################
use OCBNET::Webmerge::Mixin::Object;
################################################################################

sub initialize
{

	# get input arguments
	my ($document, $parent) = @_;

	# print initialization for now
	# print "init ", __PACKAGE__, " $node\n";

	# create the ids hash
	$document->{'sheet'} = undef;

}


################################################################################
# accessor methods
################################################################################

# return node type
sub type { 'FILE::CSS' }

################################################################################
################################################################################
1;
