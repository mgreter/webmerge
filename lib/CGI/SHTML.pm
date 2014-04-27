$VERSION = "1.29";
package CGI::SHTML;
our $VERSION = "1.29";

# -*- Perl -*-		Wed May 19 13:09:58 CDT 2004
#############################################################################
# Written by Tim Skirvin <tskirvin@ks.uiuc.edu>
# Copyright 2001-2004, Tim Skirvin and UIUC Board of Trustees.
# Redistribution terms are below.
#############################################################################

=head1 NAME

CGI::SHTML - a CGI module for parsing SSI

=head1 SYNOPSIS

  use CGI::SHTML;
  my $cgi = new CGI::SHTML;

  # Print a full page worth of info
  print $cgi->header();
  print $cgi->start_html('internal', -title=>"SAMPLE PAGE");
  # Insert content here
  print $cgi->end_html('internal', -author=>"Webmaster",
		        -address=>'webserver@ks.uiuc.edu');

  # Just parse some SSI text
  my @text = '<!--#echo var="TITLE"-->';
  print CGI::SHTML->parse_shtml(@text);

  # Use a different configuration file
  BEGIN { $CGI::SHTML::CONFIG = "/home/tskirvin/shtml.pm"; }
  use CGI::SHTML;

Further functionality is documented with the CGI module.

=head1 DESCRIPTION

In order to parse SSI, you generally have to configure your scripts to be
re-parsed through Apache itself.  This module eliminates that need by
parsing SSI headers itself, as best it can.

Some information on SSI is available at
B<http://www.cclabs.missouri.edu/things/instruction/www/html/xssi.shtml>.

=head2 VARIABLES

=over 2

=item $CGI::SHTML::CONFIG

Defines a file that has further configuration for your web site.  This is
useful to allow the module to be installed system-wide without actually
requiring changes to be internal to the file.  Note that you'll need to
reset this value *before* loading CGI::SHTML if you want it to actually
make any difference; it's loaded when you load the module.

=back

=cut

use strict;
use File::Basename;
use Time::Local;
use CGI;
use warnings;
use vars qw( @ISA $EMPTY $ROOTDIR %REPLACE %CONFIG %HEADER %FOOTER $CONFIG );
use vars qw( $IF $NOPRINT );

### User Defined Variables ####################################################
$CONFIG	 ||= "/home/webserver/conf/shtml.pm";
$ROOTDIR   = $ENV{'DOCUMENT_ROOT'} || "/Common/WebRoot";
$EMPTY 	   = "";	# Edit this for debugging
%REPLACE   = ( );
%CONFIG    = ( 'timefmt'	=>	"%D",);
%HEADER		  = (
        'internal'      =>      '/include/header-info.shtml',
        'generic'       =>      '/include/header-generic.shtml',
		    );
%FOOTER 	  = (
        'internal'      =>      '/include/footer-info.shtml',
        'generic'       =>      '/include/footer-generic.shtml',
		    );
###############################################################################

# Set some environment variables that are important for SSI
$ENV{'DATE_GMT'}      = gmtime(time);
$ENV{'DATE_LOCAL'}    = localtime(time);
$ENV{'DOCUMENT_URI'}  = join('', "http://",
			 $ENV{'SERVER_NAME'} || "localhost",
			 $ENV{'SCRIPT_NAME'} || $0 ) ;
$ENV{'LAST_MODIFIED'} = CGI::SHTML->_flastmod( $ENV{'SCRIPT_FILENAME'} || $0 );
# delete $ENV{'PATH'};

@ISA = "CGI";

if ( -r $CONFIG ) { do $CONFIG }

=head2 SUBROUTINES

=over 2

=item new ()

Invokes CGI's new() command, but blesses with the local class.  Also
performs the various local functions that are necessary.

=cut

sub new {
  my $item = CGI::new(@_);
  $$item{'NOPRINT'} = [];
  $$item{'IFDONE'} = [];
  $$item{'IF'} = 0;
  bless $item, shift; $item;
}

=item parse_shtml ( LINE [, LINE [, LINE ]] )

Parses C<LINE> as if it were an SHTML file.  Returns the parsed set of
lines, either in an array context or as a single string suitable for
printing.  All of the work is actually done by C<ssi()>.

=cut

my $rec = 0;

sub parse_shtml {
  my ($self, @lines) = @_;
  map { chomp } @lines; my $line = join("\n", @lines);
  my @parts = split m/(<!--#.*?-->)/s, $line;

 return "[SSI recursion limit execed]" if $rec > 15;

 $rec ++;

  my @return;
  while (@parts) {
    my @ssi = ();
    my $text = shift @parts || "";
    unless ($self->_noprint) {
      push @return, $text   if defined $text && $text ne '';
    }
    if (scalar @parts && $parts[0] =~ /^<!--#(\w+)\s*(.*)?-->\s*$/m) {
      @ssi = ($1, $2); shift @parts;
    }
    my $ssival = $ssi[0] ? $self->ssi(@ssi) : undef;
    unless ($self->_noprint) {
      push @return, $ssival if defined $ssival && $ssival ne '';
    }
  }

  my $final = join("", @return);
  $final =~ s/\A(?:\s*[\n\r])+\s*//g;
  $final =~ s/\s*(?:[\n\r]\s*)+\z//g;
  $rec --;
  $final;
}

sub _ifdone  { shift->_arrayset('IFDONE', @_) }
sub _noprint { shift->_arrayset('NOPRINT', @_) }

sub _arrayset {
  my ($self, $key, $val) = @_;
  my $array = $$self{$key};
  my $if = $$self{'IF'} - 1;
  if (defined $val) { $$array[$if] = $val }
  $$array[$if] || 0;
}

=item ssi ( COMMAND, ARGS )

Does the work of parsing an SSI statement.  C<COMMAND> is one of the
standard SSI "tags" - 'echo', 'include', 'fsize', 'flastmod', 'exec',
'set', 'config', 'odbc', 'email', 'if', 'goto', 'label', and 'break'.
C<ARGS> is a string containing the rest of the SSI command - it is parsed
by this function.

Note: not all commands are implemented.  In fact, all that is implemented
is 'echo', 'include', 'fsize', 'flastmod', 'exec', 'if/elif/else/endif',
and 'set'.  These are all the ones that I've actually had to use to this
point.

=cut

sub ssi {
  my ($self, $command, $args) = @_;
  my %hash = ();

  while ($args) { 		# Parse $args
    $args =~ s/^(\w+)=(\"[^\"]*\"|'.*'|\S+)\s*//;
    last unless defined($1);
    my $item = lc $1; my $val = $2;
    $val =~ s/^\"|\"$//g;
    $hash{$item} = $val if defined($val);
  }

  my $orig = $self->_noprint;
  my $if = $$self{'IF'};
  if (lc $command eq 'if' or lc $command eq 'elif') {
    if (lc $command eq 'if') { $$self{'IF'}++;  $if = $$self{'IF'}; }
    if ($self->_ifdone) { $self->_noprint(1); return "" }
    my $val = _ssieval(\%hash);
    if ($val) { $self->_noprint(0); $self->_ifdone(1); }
    else      { $self->_noprint(1); }

    my $noprint = $self->_noprint;
    return "";

  } elsif (lc $command eq 'else') {
    if ($self->_ifdone) { $self->_noprint(1); }
    else               { $self->_noprint(0); $self->_ifdone(1); }
    my $noprint = $self->_noprint;
    return "";

  } elsif (lc $command eq 'endif') {
    my $noprint = $self->_noprint(0);
    my $ifdone  = $self->_ifdone(0);
    $$self{'IF'}--;
    return "";
  }

  if (lc $command eq 'include') {
    if ( defined $hash{'virtual'} ) { $self->_file(_vfile( $hash{'virtual'} ), \%hash) }
    elsif ( defined $hash{'file'} ) { $self->_file( $hash{'file'}, \%hash ) }
    else { return "No filename offered" };
  } elsif (lc $command eq 'set') {
    my $var = $hash{'var'} || return "No variable to set";
    my $value = $hash{'value'} || "";
    $value =~ s/\{(.*)\}/$1/g;
    $value =~ s/^\$(\S+)/$ENV{$1} || $EMPTY/egx;
    $ENV{$var} = $value;
    # Should do something with "config"
    return "";
  } elsif (lc $command eq 'echo') {
    $hash{'var'} =~ s/\{(.*)\}/$1/g;
    return $ENV{$hash{'var'}} || $EMPTY;
  } elsif (lc $command eq 'exec') {
    if    ( defined $hash{'cmd'} ) { $self->_execute( $hash{'cmd'} ) || ""  }
    elsif ( defined $hash{'cgi'} ) { $self->_execute( _vfile($hash{'cgi'}) ) }
    else { return "No filename offered" };
  } elsif (lc $command eq 'fsize') {
    if    ( defined $hash{'virtual'}) { $self->_fsize(_vfile($hash{'virtual'}))}
    elsif ( defined $hash{'file'})    { $self->_fsize( $hash{'file'} ) }
    else { return "No filename offered" };
  } elsif (lc $command eq 'flastmod') {
    if (defined $hash{'virtual'})  { $self->_flastmod(_vfile($hash{'virtual'}))}
    elsif ( defined $hash{'file'}) { $self->_flastmod( $hash{'file'} ) }
    else { return "No filename offered" };
  } else { return "" }
}

=item start_html ( TYPE, OPTIONS )

Invokes C<CGI::start_html>, and includes the appropriate header file.
C<OPTIONS> is passed directly into C<CGI::start_html>, after being parsed
for the 'title' field (which is specially set).  C<TYPE> is used to decide
which header file is being used; the possibilities are in
C<$CGI::SHTML::HEADER>.

=cut

sub start_html {
  my ($self, $type, %hash) = @_;
  $type = lc $type;  $type ||= 'default';

  foreach my $key (keys %hash) {
    if (lc $key eq '-title') { $ENV{'TITLE'} = $hash{$key} }
  }

  my $command = "<!--#include virtual=\"$HEADER{$type}\"-->";

  return join("\n", CGI->start_html(\%hash), $self->parse_shtml($command) );
}

=item end_html ( TYPE, OPTIONS )

Loads the appropriate footer file out of C<$CGI::SHTML::FOOTER>, and invokes
C<CGI::end_html>.

=cut

sub end_html {
  my ($self, $type, %hash) = @_;
  $type = lc $type;  $type ||= 'default';

  my $command = "<!--#include virtual=\"$FOOTER{$type}\"-->";

  join("\n", $self->parse_shtml($command), CGI->end_html(\%hash));
}

=back

=cut

###############################################################################
### Internal Functions ########################################################
###############################################################################

### _vfile ( FILENAME )
# Gets the virtual filename out of FILENAME, based on ROOTDIR.  Also
# performs the substitutions in C<REPLACE>.

# "virtual" specifies the target relative to the domain root

sub _vfile {
  my $filename = shift || return undef;

  # If it starts with a '$' sign, then get the value out first
  if ($filename =~ /^\$\{?(\S+)\}?$/) { $filename = $ENV{$1} || ""; }

  my $hostname = $ENV{'HTTP_HOST'} || $ENV{'HOSTNAME'};
  foreach my $replace (keys %REPLACE) {
    next if ($hostname =~ /^www/);	# Hack
    $filename =~ s%$replace%$REPLACE{$replace}%g;
  }
  my $newname;
  if ($filename =~ m%^~(\w+)/(.*)$%) { $newname = "/home/$1/public_html/$2"; }
  elsif ( $filename =~ m%^[^/]% ) {
    my ($directory, $program) = $0 =~ m%^(.*)/(.*)$%;
    $newname = "$ROOTDIR/$filename"
  }
  else { $newname = "$ROOTDIR/$filename" }
  $newname =~ s%/+%/%g;  # Remove doubled-up /'s
  $newname;
}

## _file( FILE )
# Open a file and parse it with parse_shtml().
# "file" specifies the path relative to the directory of the current file
sub _file {
  use IO::HTML qw(html_file_and_encoding);
  my ($self, $file, $hash) = @_;
  # guess the encoding of the included html file
  my ($fh, $enc, $bom) = eval { html_file_and_encoding($file) }
    or warn "Couldn't open $file: $!\n"
       && return "[SSI error - could not open file: $file]";
  print "SSI-Inc with encoding charset: $enc\n" if $self->{'debug'};
  my @list = <$fh>;
  close ($fh);
  map { chomp } @list;
  if ($hash->{'dom'})
  {
		local $_;
  	use pQuery;
  	my $dom = $hash->{'dom'};
		my $pQuery = pQuery(join("\n", @list));
		return "[pQuery could not parse DOM (error)]" unless $pQuery;
		return "[pQuery could not parse DOM]" unless $pQuery->length;
		my $node = $pQuery->find($dom) if $pQuery;
		return "[DOM root node not found (error)]" unless $node;
		return "[DOM root node not found]" unless $node->length;
		@list = ($node->html) if $node;
  }

  # concat the fill response code
  my $data = join("\n", @list);
  # apply some minimalistic templating
  $data =~ s/\$\{([a-zA-Z0-9]+)(?:\s*\|\|\s*(.*?)\s*)?\}/
  	exists $hash->{$1} ? $hash->{$1} : $2
  /egx;
  # get just a certain node, remove others
  return $self->parse_shtml($data);
}

## _execute( CMD )
# Run a command and get the information about it out.  This isn't as
# secure as we'd like it to be...
sub _execute {
  my ($self, $cmd) = @_;
  foreach (qw( IFS CDPATH ENV BASH_ENV PATH ) ) { $ENV{$_} = ""; }
	$ENV{'PATH'} = dirname $ENV{'ComSpec'} if (exists $ENV{'ComSpec'});
  my ($command) = $cmd =~ /^(.*)$/;	# Not particularly secure
  open ( COMMAND, "$command |" ) or warn "Couldn't open $command\n";
  my @list = <COMMAND>;
  close (COMMAND);
  map { chomp } @list;
  return "" unless scalar(@list) > 0;	# Didn't return anything
  # Take out the "Content-type:" part, if it's a CGI - note, THIS IS A HACK
  if ( scalar(@list) > 1 && $list[0] =~ /^Content-type: (.*)$/i) {
    shift @list;  shift @list;
  }
  wantarray ? @list : join("\n", @list);
}

## _flastmod( FILE )
## _fsize( FILE )
# Last modification and file size of the given FILE, respectively.
sub _flastmod { localtime( (stat($_[1]))[9] || 0 ); }
sub _fsize    {
  my $size = ((stat($_[1]))[7]) || 0;
  if ($size >= 1048576) {
    sprintf("%4.1fMB", $size / 1048576);
  } elsif ($size >= 1024) {
    sprintf("%4.1fKB", $size / 1024);
  } else {
    sprintf("%4d bytes", $size);
  }
}

## _ssieval( HASHREF )
# Evaluates the expression with 'var' or 'expr'.  Meant for use with
# if/elif clauses.  This actually more-or-less works!  It's also very
# dangerous, though, since it uses 'eval'.  Then again, given that we're
# already giving the user the capacity to invoke random pieces of code,
# it's not realy that much of a stretch...
sub _ssieval {
  my $hash = shift;
  if (my $var  = $$hash{'var'})  { return $var ? 1 : 0 }
  if (my $eval = $$hash{'expr'}) {
    $eval =~ s/\s*\$(?:\{(\S+?)\}|(\S+?))\s*
	      / join('', "'", $ENV{$1 || $2} || "", "'" ) /egx;
    my $val = eval($eval);
    return $val ? 1 : 0;	# Need to do more here.
  }
  0
}

1;

