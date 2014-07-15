################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::Action::Copy;
################################################################################
use base qw(OCBNET::Webmerge::IO::File);
################################################################################

use strict;
use warnings;

################################################################################
require OCBNET::File::Find;
require OCBNET::File::Copy;
################################################################################
use OCBNET::Webmerge qw(ison);
################################################################################

sub execute
{

	my ($node) = @_;

	my $src = $node->attr('src');
	my $dst = $node->attr('dst');
	my $chroot = $node->attr('chroot');
	my $pattern = $node->attr('pattern');
	my $maxdept = $node->attr('maxdept');
	my $recursive = $node->attr('recursive');
	# change to ison(recursive) and use maxdepth
	# otherwise recursive="1" is only one level
	# or think of some other smart way for this

	$src = $node->respath($src);
	$dst = $node->respath($dst);

	my %opts = (
		'base' => '.',
		'chroot' => $chroot,
		'recursive' => $recursive,
		# 'read' => sub { warn "read $_[0]\n" },
		# 'write' => sub { warn "write $_[0]\n" },
	);

	# copy into dst
	if (defined $pattern)
	{

		warn "cp $src($pattern) $dst\n";
		my @files = OCBNET::File::Find::find($pattern, %opts);
		OCBNET::File::Copy::xcopy(\@files, $dst, %opts);

	}
	# copy to dst
	elsif ($recursive)
	{
		warn "cp rec $src $dst\n";
		OCBNET::File::Copy::xcopy($src, $dst, %opts);
	}
	else
	{
		OCBNET::File::Copy::fcopy($src, $dst, %opts);
		warn "cp file $src $dst\n";
	}


#OCBNET::File::Copy::xcopy('.', 'y:\\tcp\\', %opts);


#	die "copy $src $dst"

}

################################################################################
################################################################################
1;
