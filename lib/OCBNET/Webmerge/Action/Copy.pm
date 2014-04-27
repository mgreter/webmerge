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
use OCBNET::File::Find qw(find);
use OCBNET::File::Copy qw(xcopy);
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
	my $recursive = ison $node->attr('recursive');

	$src = $node->respath($src);
	$dst = $node->respath($dst);

	my %opts = (
		'base' => $src,
		'chroot' => $chroot,
		'recursive' => $recursive,
		'read' => sub { warn "read $_[0]\n" },
		'write' => sub { warn "write $_[0]\n" },
	);

	# copy into dst
	if (defined $pattern)
	{

		warn "cp $src($pattern) $dst\n";
		my @files = find($pattern, %opts);
		xcopy(\@files, $dst, %opts);

	}
	# copy to dst
	elsif ($recursive)
	{
		warn "cp rec $src $dst\n";
		xcopy($src, $dst, %opts);
	}
	else
	{
		warn "cp file $src $dst\n";
	}


#xcopy('.', 'y:\\tcp\\', %opts);


#	die "copy $src $dst"

}

################################################################################
################################################################################
1;
