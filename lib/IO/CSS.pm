###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of IO-CSS (GPL3)
####################################################################################################
package IO::CSS;
####################################################################################################

use strict;
use warnings;
use Carp qw(croak);

####################################################################################################

# define version for cpan
our $VERSION = 'cac8-dirty';

####################################################################################################

# load exporter and inherit from it
BEGIN { use Exporter qw(); our @ISA = qw(Exporter); }

# define our functions that will be exported
BEGIN { our @EXPORT = qw(css_file); }

# define our functions that can be exported
BEGIN { our @EXPORT_OK = qw(
                            sniff_encoding
                            find_charset_in
                            css_file_and_encoding
                           ); }

# define some export tags similar to IO::HTML
BEGIN { our %EXPORT_TAGS = ( rw  => [qw(
                                        css_file
                                        css_file_and_encoding
                                    )],
                             all => [qw(
                                        sniff_encoding
                                        find_charset_in
                                        css_file_and_encoding
                             )]
                           ); }

####################################################################################################
use Encode 2.10 qw(decode encode find_encoding); # need utf-8-strict encoding
####################################################################################################

# define the default encoding if not previousely set
# use cp 1252 for windows (still the default) and utf8 otherwise
our $default_encoding ||= $^O eq 'MSWin32' ? 'cp1252' : 'utf8';

####################################################################################################
# open a filehandle to the css file
# will seek after the charset rules
####################################################################################################

# Note: I made css_file and css_file_and_encoding separate functions
# (instead of making css_file context-sensitive) because I wanted to
# use css_file in function calls (i.e. list context) without having
# to write "scalar css_file" all the time.
sub css_file
{
	# return just the filehandle
	(&css_file_and_encoding)[0];
}
# EO css_file

####################################################################################################
# internal helper function
####################################################################################################

# helper for wantarray returns
sub wa(@) { wantarray ? @_ : $_[0] }

####################################################################################################
# open a filehandle to the css file
# will seek after the charset rules
# returns also the encoding and offset
####################################################################################################

sub css_file_and_encoding
{

	# get passed input arguments
	my ($filename, $options) = @_;

	# optional arguments
	$options ||= {};

	# open the file in raw encoding (read the real bytes not chars for now)
	open(my $fh, '<:raw', $filename) or croak "Failed to open $filename: $!";

	# try to get encoding from bom or charset from given filename
	my ($encoding, $bom, $off) = sniff_encoding($fh, $filename, $options);

	# use the default encoding if no result by sniffing
	$encoding = $default_encoding unless defined $encoding;

	# croak if there was no default encoding defined at all (wierd)
	croak "No default encoding specified" unless defined($encoding);

	# obey the encoding options and fetch object from encode
	$encoding = find_encoding($encoding) if $options->{encoding};

	# get the encoding name either from encoding object or string
	my $encoding_name = $options->{encoding} ? $encoding->name : $encoding;

	# make crlf conversion optional
	my $crlf = $options->{crlf} ? ':crlf' : '';

	# apply the given encoding rules to the filehandle
	binmode $fh, sprintf(":encoding(%s)%s", $encoding_name, $crlf);

	# return all interesting parts
	return ($fh, $encoding, $bom, $off);

}
# EO css_file_and_encoding

####################################################################################################
# maybe allow some comments before the charset declaration
####################################################################################################

# match text in apos or quotes
# **************************************************************************************************
our $re_apo = qr/(?:[^\'\\]+|\\.)*/s;
our $re_quot = qr/(?:[^\"\\]+|\\.)*/s;
our $re_name = qr/[_a-zA-Z][_a-zA-Z0-9\-]*/;

# http://www.w3.org/TR/CSS2/syndata.html#charset
# https://bugzilla.mozilla.org/show_bug.cgi?id=796882
# **************************************************************************************************
sub find_charset_in
{

	# get data from input into $_
	# read directly to avoid copy
	for (shift)
	{
		# get optional options
		my $options = shift || {};
		# search the whole text
		if (m/^(.*?\@charset\s*(?:
		                          \"($re_quot)\" |
		                          \'($re_apo)\' |
		                          ($re_name)
		                       )
		       (?:\r?\n|\s)*;?)
		/sx)
		{

			# get from matches
			my $charset;

			# encoding might be in any match
			if (defined $2) { $charset = $2; }
			elsif (defined $3) { $charset = $3; }
			elsif (defined $4) { $charset = $4; }

			# this seems to happen very often (128-159)
			$charset = 'cp1252' if lc $charset eq 'iso-8859-1';

			# try to resolve to fq name via encode
			my $encoding = find_encoding($charset);
			# return failure if nothing is found
			return (undef, 0) unless $encoding;
			# return whole encoding object if requested
			return wa $encoding, $+[0] if $options->{encoding};
			# otherwise return just the name
			return wa $encoding->name, $+[0];

		}

	}
	# EO for string

	# did not find any
	return undef;

}
# EO find_charset_in

####################################################################################################
# create data for bom matching (inspired from File::BOM)
####################################################################################################

# list all supported bom encodings (on read)
my @encodings = qw(utf-8-strict UTF-16BE UTF-16LE UTF-32BE UTF-32LE);
# list additional bom encodings (on write)
my @additional = qw(UCS-2 iso-10646-1 utf8 UTF-8 utf-8-strict);

# create the lookup hash for bom to encoding (on read)
our %bom2enc = ( map { encode($_, "\x{feff}") => $_ } @encodings );
# create the lookup hash for bom to encoding (on write)
our %enc2bom = ( reverse(%bom2enc), map { $_ => encode($_, "\x{feff}") } @additional );

# create the lookup hash for charset to encoding (on read)
# filter out utf-8-strict, as this would match any ascii charset
our %cset2enc = ( map { encode($_, '@charset') => $_ } grep { $_ ne 'utf-8-strict'} @encodings );
# create the lookup hash for charset to encoding (on write)
our %enc2cset = ( reverse(%cset2enc), map { $_ => encode($_, '@charset') } @additional );

# sort boms by listening the longest ones first
my @boms = sort { length $b <=> length $a } keys %bom2enc;
my @csets = sort { length $b <=> length $a } keys %cset2enc;

# create regular expressions to match any bom or charset string
my $re_boms_str = join "|", @boms; our $re_boms = qr/\A($re_boms_str)/o;
my $re_csets_str = join "|", @csets; our $re_csets = qr/\A($re_csets_str)/o;

####################################################################################################
# main function to sniff the encoding
# we will first check for a bom, then we will check
# for a @charset rule inside the first 1024 bytes.
####################################################################################################

sub sniff_encoding
{

	# get passed input arguments
	my ($fh, $filename, $options) = @_;

	# check if we are called in scalar mode
	my ($scalar, $pos, $buf) = UNIVERSAL::isa( $fh, "SCALAR" ), 0;

	# filename is only used for debug purposes
	$filename = '[file]' unless defined $filename;

	# optional arguments
	$options ||= {};

	# real file mode
	unless ($scalar)
	{
		# current position
		$pos = tell $fh;
		# give some debug message if we cannot seek
		croak "Could not seek $filename: $!" if $pos < 0;
		# try to load a maximum amount of chars into our buffer (or croak on error)
		croak "Could not read $filename: $!" unless defined read $fh, $buf, 1024;
		# try to seek back to the initial position (if not in scalar mode)
		seek $fh, $pos, 0 or croak "Could not seek $filename: $!";
	}
	# or buffer from scalar
	else { $buf = ${$fh} }

	# declare local variables
	my ($bom_off, $bom_enc) = (0);

	# match for all possibilites in one run
	if (my (@match) = $buf =~ /^(?:$re_boms|$re_csets)/)
	{
		# get the encoding from one of the matches
		$bom_enc = $bom2enc{$match[0]} if defined $match[0];
		$bom_enc = $cset2enc{$match[1]} if defined $match[1];
		# assertion (should not happen as we checked before)
		die "illegal state: no match" unless defined $bom_enc;
		# set the bom length (but only if a bom was matched)
		$bom_off = length($enc2bom{$bom_enc}) if defined $match[0];
	}

	# get text from buffer to search
	my $head = substr($buf, 0, 1024);

	# croak on very esoteric utf32 variations (not implement in perl)
	croak "cannot handle UCS-4-2143 encoding" if $bom_enc && $bom_enc eq "UCS-4-2143";
	croak "cannot handle UCS-4-3412 encoding" if $bom_enc && $bom_enc eq "UCS-4-3412";

	# check if we are loading a multibyte encoding
	my $multibyte = $bom_off == 2 || $bom_off == 4;

	# decode lead if a utf16 or utf32 header was found
	$head = decode($bom_enc, $head) if $multibyte;

	# now call find charset to search lead text for meta rule
	# this uses regular expression which will only work in utf8
	my ($meta_enc, $meta_off) = find_charset_in($head, $options);

	my $meta_enc_name = ref $meta_enc ? $meta_enc->name : $meta_enc;
	# check for unhandled situations (multibyte encoding differs from charset)
	if ($bom_enc && $meta_enc && $bom_enc ne $meta_enc_name && $bom_off != 3)
	{ croak "have different bom($bom_enc) and charset($meta_enc)" }

	# adjust for found bom/charset definiton
	# the filename to load could have unicode
	if ($bom_enc && $meta_off && $multibyte)
	{
		# get the leading text inclusive meta rule
		my $lead = substr($buf, $bom_off || 0, $meta_off);
		# encode into original multibyte encoding
		$lead = encode($bom_enc, $lead);
		# get real byte offset for lead
		$meta_off = length($lead);
	}

	# get the final encoding from meta or bom
	my $encoding = $meta_enc ? $meta_enc : $bom_enc;

	# check if we do have some encoding
	if ($encoding && ($bom_off || $meta_off) && not $scalar)
	{
		# seek to position right after encoding definition in file
		seek $fh, $bom_off + $meta_off, 1 or croak "Could not seek $filename: $!";
	}
	# otherwise try if it is utf8
	elsif (not defined $encoding)
	{
		# try to decode as utf8 strict (but be quiet on errors)
		my $decoded = decode('utf-8-strict', $buf, Encode::FB_QUIET);
		# check if valid UTF-8 with at least one multi-byte character
		if ($buf =~ /^(?:                             # nothing left over
		               | [\xC2-\xDF]                  # incomplete 2-byte char
		               | [\xE0-\xEF] [\x80-\xBF]?     # incomplete 3-byte char
		               | [\xF0-\xF4] [\x80-\xBF]{0,2} # incomplete 4-byte char
		              )\z/x and $decoded =~ /[^\x00-\x7F]/)
		{
			$encoding = 'utf-8-strict';
		}
	}

	# try to resolve the encoding name via perl encode module
	if (defined $encoding and $options->{encoding} and not ref $encoding)
	{
		# call find encoding on perl encode modules
		$encoding = find_encoding($encoding);
	}

	# check if the caller wants an array or not
	return wantarray ? ($encoding, $bom_off, $meta_off) : $encoding;

} # end sniff_encoding

####################################################################################################

# Shortcuts for people who don't like exported functions:
*file               = \&css_file;
*file_and_encoding  = \&css_file_and_encoding;

####################################################################################################
####################################################################################################
1;
