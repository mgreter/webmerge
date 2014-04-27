#---------------------------------------------------------------------
package IO::CSS;
#
# Copyright 2014 Marcel Greter
# Copyright 2012 Christopher J. Madsen
#
# NOTE: This module is a copy of IO::HTML with just a few additions to
# parse css charset definitions instead of html. I simply replaced all
# occurences of HTML to CSS otherwise. The documentation is incorrect!
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 14 Jan 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Open a CSS file with automatic charset detection
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

use Carp 'croak';
use Encode 2.10 qw(decode find_encoding); # need utf-8-strict encoding
use Exporter 5.57 'import';

our $VERSION = '1.00';
# This file is part of IO-CSS 1.00 (February 23, 2013)

our $default_encoding ||= 'cp1252';

our @EXPORT    = qw(css_file);
our @EXPORT_OK = qw(find_charset_in css_file_and_encoding css_outfile
                    sniff_encoding);

our %EXPORT_TAGS = (
  rw  => [qw( css_file css_file_and_encoding css_outfile )],
  all => [ @EXPORT, @EXPORT_OK ],
);

#=====================================================================


sub css_file
{
  (&css_file_and_encoding)[0]; # return just the filehandle
} # end css_file


# Note: I made css_file and css_file_and_encoding separate functions
# (instead of making css_file context-sensitive) because I wanted to
# use css_file in function calls (i.e. list context) without having
# to write "scalar css_file" all the time.

sub css_file_and_encoding
{
  my ($filename, $options) = @_;

  $options ||= {};

  open(my $in, '<:raw', $filename) or croak "Failed to open $filename: $!";


  my ($encoding, $bom) = sniff_encoding($in, $filename, $options);

  if (not defined $encoding) {
    croak "No default encoding specified"
        unless defined($encoding = $default_encoding);
    $encoding = find_encoding($encoding) if $options->{encoding};
  } # end if we didn't find an encoding

  binmode $in, sprintf(":encoding(%s):crlf",
                       $options->{encoding} ? $encoding->name : $encoding);

  return ($in, $encoding, $bom);
} # end css_file_and_encoding
#---------------------------------------------------------------------


sub css_outfile
{
  my ($filename, $encoding, $bom) = @_;

  if (not defined $encoding) {
    croak "No default encoding specified"
        unless defined($encoding = $default_encoding);
  } # end if we didn't find an encoding
  elsif (ref $encoding) {
    $encoding = $encoding->name;
  }

  open(my $out, ">:encoding($encoding)", $filename)
      or croak "Failed to open $filename: $!";

  print $out "\x{FeFF}" if $bom;

  return $out;
} # end css_outfile
#---------------------------------------------------------------------


sub sniff_encoding
{
  my ($in, $filename, $options) = @_;

  $filename = 'file' unless defined $filename;
  $options ||= {};

  my $pos = tell $in;
  croak "Could not seek $filename: $!" if $pos < 0;

  croak "Could not read $filename: $!" unless defined read $in, my $buf, 1024;

  seek $in, $pos, 0 or croak "Could not seek $filename: $!";

  # Check for BOM:
  my $bom;
  my ($encoding, $offset) = do {
    if ($buf =~ /^\xFe\xFF/) {
      $bom = 2;
      ('UTF-16BE', 0);
    } elsif ($buf =~ /^\xFF\xFe/) {
      $bom = 2;
      ('UTF-16LE', 0);
    } elsif ($buf =~ /^\xEF\xBB\xBF/) {
      $bom = 3;
      ('utf-8-strict', 0);
    } else {
      find_charset_in($buf, $options); # check for <meta charset>
    }
  }; # end $encoding

  if ($bom || $offset) {
    seek $in, ($bom || 0) + ($offset || 0), 1 or croak "Could not seek $filename: $!";
    $bom = 1;
  }
  elsif (not defined $encoding) { # try decoding as UTF-8
    my $test = decode('utf-8-strict', $buf, Encode::FB_QUIET);
    if ($buf =~ /^(?:                   # nothing left over
         | [\xC2-\xDF]                  # incomplete 2-byte char
         | [\xE0-\xEF] [\x80-\xBF]?     # incomplete 3-byte char
         | [\xF0-\xF4] [\x80-\xBF]{0,2} # incomplete 4-byte char
        )\z/x and $test =~ /[^\x00-\x7F]/) {
      $encoding = 'utf-8-strict';
    } # end if valid UTF-8 with at least one multi-byte character:
  } # end if testing for UTF-8

  if (defined $encoding and $options->{encoding} and not ref $encoding) {
    $encoding = find_encoding($encoding);
  } # end if $encoding is a string and we want an object

  return wantarray ? ($encoding, $bom) : $encoding;
} # end sniff_encoding

#=====================================================================
# Based on CSS5 8.2.2.1 Determining the character encoding:

#---------------------------------------------------------------------

# match text in apos or quotes
#---------------------------------------------------------------------
our $re_apo = qr/(?:[^\'\\]+|\\.)*/s;
our $re_quot = qr/(?:[^\"\\]+|\\.)*/s;
our $re_name = qr/[_a-zA-Z][_a-zA-Z0-9\-]*/;

sub find_charset_in
{
  for (shift) {
    my $options = shift || {};
    my $stop = length > 1024 ? 1024 : length; # search first 1024 bytes
    if (m/(\@charset\s*(?:
      \'($re_apo)\' |
      \"($re_quot)\" |
      ($re_name)
    )(?:\r?\n|\s)*;?)/x)
    {
      my $charset;
      if (defined $2) { $charset = $2; }
      elsif (defined $3) { $charset = $3; }
      elsif (defined $4) { $charset = $4; }
      $charset = 'UTF-8'  if $charset =~ /^utf-?16/;
      $charset = 'cp1252' if $charset eq 'iso-8859-1'; # people lie
      if (my $encoding = find_encoding($charset)) {
        return ($options->{encoding} ? $encoding : $encoding->name, length($1));
      }
      return (undef, 0);
    }
  } # end for string

  return undef;                 # Couldn't find a charset
} # end find_charset_in
#---------------------------------------------------------------------


# Shortcuts for people who don't like exported functions:
*file               = \&css_file;
*file_and_encoding  = \&css_file_and_encoding;
*outfile            = \&css_outfile;

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

IO::CSS - Open a CSS file with automatic charset detection

=head1 VERSION

This document describes version 1.00 of
IO::CSS, released February 23, 2013.

=head1 SYNOPSIS

  use IO::CSS;                 # exports css_file by default
  use CSS::TreeBuilder;

  my $tree = CSS::TreeBuilder->new_from_file(
               css_file('foo.css')
             );

  # Alternative interface:
  open(my $in, '<:raw', 'bar.css');
  my $encoding = IO::CSS::sniff_encoding($in, 'bar.css');

=head1 DESCRIPTION

IO::CSS provides an easy way to open a file containing CSS while
automatically determining its encoding.  It uses the CSS5 encoding
sniffing algorithm specified in section 8.2.2.1 of the draft standard.

The algorithm as implemented here is:

=over

=item 1.

If the file begins with a byte order mark indicating UTF-16LE,
UTF-16BE, or UTF-8, then that is the encoding.

=item 2.

If the first 1024 bytes of the file contain a C<< <meta> >> tag that
indicates the charset, and Encode recognizes the specified charset
name, then that is the encoding.  (This portion of the algorithm is
implemented by C<find_charset_in>.)

The C<< <meta> >> tag can be in one of two formats:

  <meta charset="...">
  <meta http-equiv="Content-Type" content="...charset=...">

The search is case-insensitive, and the order of attributes within the
tag is irrelevant.  Any additional attributes of the tag are ignored.
The first matching tag with a recognized encoding ends the search.

=item 3.

If the first 1024 bytes of the file are valid UTF-8 (with at least 1
non-ASCII character), then the encoding is UTF-8.

=item 4.

If all else fails, use the default character encoding.  The CSS5
standard suggests the default encoding should be locale dependent, but
currently it is always C<cp1252> unless you set
C<$IO::CSS::default_encoding> to a different value.  Note:
C<sniff_encoding> does not apply this step; only C<css_file> does
that.

=back

=head1 SUBROUTINES

=head2 css_file

  $filehandle = css_file($filename, \%options);

This function (exported by default) is the primary entry point.  It
opens the file specified by C<$filename> for reading, uses
C<sniff_encoding> to find a suitable encoding layer, and applies it.
It also applies the C<:crlf> layer.  If the file begins with a BOM,
the filehandle is positioned just after the BOM.

The optional second argument is a hashref containing options.  The
possible keys are described under C<find_charset_in>.

If C<sniff_encoding> is unable to determine the encoding, it defaults
to C<$IO::CSS::default_encoding>, which is set to C<cp1252>
(a.k.a. Windows-1252) by default.  According to the standard, the
default should be locale dependent, but that is not currently
implemented.

It dies if the file cannot be opened.


=head2 css_file_and_encoding

  ($filehandle, $encoding, $bom)
    = css_file_and_encoding($filename, \%options);

This function (exported only by request) is just like C<css_file>,
but returns more information.  In addition to the filehandle, it
returns the name of the encoding used, and a flag indicating whether a
byte order mark was found (if C<$bom> is true, the file began with a
BOM).  This may be useful if you want to write the file out again
(especially in conjunction with the C<css_outfile> function).

The optional second argument is a hashref containing options.  The
possible keys are described under C<find_charset_in>.

It dies if the file cannot be opened.  The result of calling it in
scalar context is undefined.


=head2 css_outfile

  $filehandle = css_outfile($filename, $encoding, $bom);

This function (exported only by request) opens C<$filename> for output
using C<$encoding>, and writes a BOM to it if C<$bom> is true.
If C<$encoding> is C<undef>, it defaults to C<$IO::CSS::default_encoding>.
C<$encoding> may be either an encoding name or an Encode::Encoding object.

It dies if the file cannot be opened.


=head2 sniff_encoding

  ($encoding, $bom) = sniff_encoding($filehandle, $filename, \%options);

This function (exported only by request) runs the CSS5 encoding
sniffing algorithm on C<$filehandle> (which must be seekable, and
should have been opened in C<:raw> mode).  C<$filename> is used only
for error messages (if there's a problem using the filehandle), and
defaults to "file" if omitted.  The optional third argument is a
hashref containing options.  The possible keys are described under
C<find_charset_in>.

It returns Perl's canonical name for the encoding, which is not
necessarily the same as the MIME or IANA charset name.  It returns
C<undef> if the encoding cannot be determined.  C<$bom> is true if the
file began with a byte order mark.  In scalar context, it returns only
C<$encoding>.

The filehandle's position is restored to its original position
(normally the beginning of the file) unless C<$bom> is true.  In that
case, the position is immediately after the BOM.

Tip: If you want to run C<sniff_encoding> on a file you've already
loaded into a string, open an in-memory file on the string, and pass
that handle:

  ($encoding, $bom) = do {
    open(my $fh, '<', \$string);  sniff_encoding($fh)
  };

(This only makes sense if C<$string> contains bytes, not characters.)


=head2 find_charset_in

  $encoding = find_charset_in($string_containing_CSS, \%options);

This function (exported only by request) looks for charset information
in a C<< <meta> >> tag in a possibly incomplete CSS document using
the "two step" algorithm specified by CSS5.  It does not look for a BOM.
Only the first 1024 bytes of the string are checked.

It returns Perl\'s canonical name for the encoding, which is not
necessarily the same as the MIME or IANA charset name.  It returns
C<undef> if no charset is specified or if the specified charset is not
recognized by the Encode module.

The optional second argument is a hashref containing options.  The
following keys are recognized:

=over

=item C<encoding>

If true, return the L<Encode::Encoding> object instead of its name.
Defaults to false.

=item C<need_pragma>

If true (the default), follow the CSS5 spec and examine the
C<content> attribute only of C<< <meta http-equiv="Content-Type" >>.
If set to 0, relax the CSS5 spec, and look for "charset=" in the
C<content> attribute of I<every> meta tag.

=back

=head1 EXPORTS

By default, only C<css_file> is exported.  Other functions may be
exported on request.

For people who prefer not to export functions, all functions beginning
with C<css_> have an alias without that prefix (e.g. you can call
C<IO::CSS::file(...)> instead of C<IO::CSS::css_file(...)>.  These
aliases are not exportable.

=for Pod::Coverage
file
file_and_encoding
outfile

The following export tags are available:

=over

=item C<:all>

All exportable functions.

=item C<:rw>

C<css_file>, C<css_file_and_encoding>, C<css_outfile>.

=back

=head1 SEE ALSO

The CSS5 specification, section 8.2.2.1 Determining the character encoding:
L<http://www.w3.org/TR/CSS5/parsing.css#determining-the-character-encoding>

=head1 DIAGNOSTICS

=over

=item C<< Could not read %s: %s >>

The specified file could not be read from for the reason specified by C<$!>.


=item C<< Could not seek %s: %s >>

The specified file could not be rewound for the reason specified by C<$!>.


=item C<< Failed to open %s: %s >>

The specified file could not be opened for reading for the reason
specified by C<$!>.


=item C<< No default encoding specified >>

The C<sniff_encoding> algorithm didn\'t find an encoding to use, and
you set C<$IO::CSS::default_encoding> to C<undef>.


=back

=head1 CONFIGURATION AND ENVIRONMENT

IO::CSS requires no configuration files or environment variables.

=head1 DEPENDENCIES

IO::CSS has no non-core dependencies for Perl 5.8.7+.  With earlier
versions of Perl 5.8, you need to upgrade L<Encode> to at least
version 2.10, and
you may need to upgrade L<Exporter> to at least version
5.57.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-IO-CSS AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=IO-CSS >>.

You can follow or contribute to IO-CSS\'s development at
L<< http://github.com/madsen/io-css >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
