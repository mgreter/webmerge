###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-CSS3 (GPL3)
####################################################################################################
package OCBNET::CSS3::DOM::Comment;
####################################################################################################

use strict;
use warnings;

####################################################################################################
use base 'OCBNET::CSS3';
####################################################################################################

our @readers;

####################################################################################################

# static function only
# never call as object
sub register
{

	# get input arguments
	my ($reader) = @_;

	# add additional reader
	push @readers, $reader;

}
# EO fn register

####################################################################################################

# static getter
#**************************************************************************************************
sub type { return 'comment' }

####################################################################################################

# set the readed comment
# parse keys and values
sub set
{

	# get input arguments
	my ($self, $text) = @_;

	# call super class method
	$self->SUPER::set($text);

	# call each reader for the given text
	$_->($self, $text) foreach @readers;

	# instance
	return $self;

}
# EO sub set

####################################################################################################

# load regex for comments
#**************************************************************************************************
use OCBNET::CSS3::Regex::Comments;

# add basic extended type with highest priority
#**************************************************************************************************
unshift @OCBNET::CSS3::types, [
	qr//is,
	'OCBNET::CSS3::DOM::Comment',
	sub { $_[0] =~ m/\A\s*$re_comment\s*\z/is }
];

####################################################################################################
####################################################################################################
1;