################################################################################
# Copyright 2014 by Marcel Greter
# This file is part of Webmerge (GPL3)
################################################################################
package OCBNET::Webmerge::File::Files;
################################################################################
use base qw(OCBNET::Webmerge::IO::File);
################################################################################

use strict;
use warnings;


################################################################################
# return further inputs
# who calls me anyway?
################################################################################
use File::Glob qw(:globally :nocase bsd_glob);
################################################################################
use OCBNET::Webmerge qw(isset notset ison isoff);
################################################################################
use File::Basename qw(fileparse);
################################################################################
use File::Spec::Functions qw(catfile rel2abs file_name_is_absolute);
################################################################################
use List::MoreUtils qw(uniq);
################################################################################
use Cwd qw(getcwd);
################################################################################

sub files
{

	# get arguments
	my ($input) = @_;

	# fetch some attributes
	my $path = $input->attr('path');
	my $file = $input->attr('file');

	# maybe we have no path and no file given
	return ($input) unless (defined $path && defined $file);

	# default to workroot if nothing is given
	$path = $input->workroot unless $path;

	# check if we should glob recursive
	my $rec = ison $input->attr('recursive');

	# if only path exists
	unless (defined $file)
	{
		# split into dirname and basename
		($file, $path) = ($path, '.');
	}

	# maybe should be supported?
	# not sure what it means yet!
	unless (defined $path)
	{
		die "propably just a single input";
	}

	# collect paths and files
	my (@paths, @files) = ($path);

	# change into workroot
	chdir $input->workroot;

	# make them unique
	@paths = uniq @paths;

	# process paths recursive
	for (my $i = 0; $i < scalar(@paths); $i++)
	{

		my $pattern = file_name_is_absolute($file) ?
		              $file : catfile($paths[$i], $file);

		# support multiple files via glob
		push @files, grep { -f $_ }
		             map { rel2abs $_ }
		             sort ( bsd_glob($pattern) );

		# add better error handling
		my $rv = opendir (my $dh, $paths[$i]);
		# check if directory has been opened
		die "opendir: $!: " . $paths[$i] unless $rv;
		# fetch and sort all entities
		my @ents = sort readdir($dh);

		# process sorted entities
		while (my $ent = shift @ents)
		{
			next unless $rec;
			# skip current and parent directory
			next if $ent eq '.' || $ent eq '..';
			# create a partialy complete filename
			my $entity = catfile($paths[$i], $ent);
			next unless -d $entity;
			# collect more paths to search in
			push @paths, $entity;
			# make paths unique as we may check the
		}
		# same directory for multiple file patterns
		@paths = uniq @paths;

		# loop until rec reaches 0
		# holds -1 to loop forever
		last unless $rec --;
	}

	# map to real objects
	# so you can call methods
	map
	{

		# create a new object
		# use same class name
		my $file = $input->new($input);
		# only attach the parent
		# do not add to children
		$file->{'parent'} = $input;
		# set the tag to the same name
		# just in case someone is curious
		$file->{'tag'} = $input->{'tag'};
		# copy the complete attribute hash
		$file->{'attr'} = { %{$input->{'attr'}} };
		# finally set the actual file path
		$file->{'attr'}->{'path'} = $_;
		# object for map
		$file;

	} @files;

}
# EO sub files

################################################################################
################################################################################
1;
