###################################################################################################
package RTP::IO::AtomicFile;
###################################################################################################
# fork safe implementation of IO::AtomicFile
###################################################################################################

# Be strict:
use strict;

###################################################################################################

# External modules:
use base "IO::AtomicFile";

###################################################################################################

#------------------------------
# new ARGS...
#------------------------------
# Class method, constructor.
# Any arguments are sent to open().
#
sub new
{
	my $pckg = shift;
	my $self = $pckg->SUPER::new();
	${*$self}{'io_atomicfile_pid'} = $$;
	$self->open(@_) if @_;
	$self;
}

#------------------------------
# DESTROY
#------------------------------
# Destructor.
#
sub DESTROY {
	my $self = shift;
	return if ${*$self}{'io_atomicfile_pid'} ne $$;
	$self->SUPER::DESTROY(@_);
}

#------------------------------
# open PATH, MODE
#------------------------------
# Class/instance method.
#
sub open
{
	my $self = shift;
	if (${*$self}{'io_atomicfile_pid'} ne $$)
	{ die "atomic file operation of foreign pid"; }
	$self->SUPER::open(@_);
}

#------------------------------
# _closed [YESNO]
#------------------------------
# Instance method, private.
# Are we already closed?  Argument sets new value, returns previous one.
#
sub _closed
{
	my $self = shift;
	if (${*$self}{'io_atomicfile_pid'} ne $$)
	{ die "atomic file operation of foreign pid"; }
	$self->SUPER::_closed(@_);
}

#------------------------------
# close
#------------------------------
# Instance method.
# Close the handle, and rename the temp file to its final name.
#
sub close
{
	my $self = shift;
	if (${*$self}{'io_atomicfile_pid'} ne $$)
	{ die "atomic file operation of foreign pid"; }
	$self->SUPER::close(@_);
}

#------------------------------
# delete
#------------------------------
# Instance method.
# Close the handle, and delete the temp file.
#
sub delete
{
	my $self = shift;
	if (${*$self}{'io_atomicfile_pid'} ne $$)
	{ die "atomic file operation of foreign pid"; }
	$self->SUPER::delete(@_);
}

#------------------------------
# detach
#------------------------------
# Instance method.
# Close the handle, but DO NOT delete the temp file.
#
sub detach
{
	my $self = shift;
	if (${*$self}{'io_atomicfile_pid'} ne $$)
	{ die "atomic file operation of foreign pid"; }
	$self->SUPER::detach(@_);
}

###################################################################################################
###################################################################################################
1;