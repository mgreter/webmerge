# from http://www.perlmonks.org/?node_id=49335
# 26.06.2012 added can_dequeue function (mgr@rtp.ch)
package Fork::Queue;

use strict;
use warnings;

use Socket;

sub new {
    my($this) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->mksockpair();
    return $self;
}
# make the socketpair
sub mksockpair {
    my($self)=@_;
    socketpair(my $reader, my $writer, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
    if ($^O ne "MSWin32")
    {
      shutdown($reader,1);
      shutdown($writer,0);
    }
    $self->{'READER'}=$reader;
    $self->{'WRITER'}=$writer;
}
# method to put something on the queue
sub enqueue {
    my($self,@data)=@_;
    my($header,$buffer,$tosend);
    my($handle)=$self->{'WRITER'};
    foreach my $item (@data) {
        $header=pack("N",length($item));
        $buffer=$header . $item;
        $tosend=length($buffer);
        my $rv = print $handle $buffer;
        die "write error : $!" unless defined $rv;
        die "write disconnected" if $rv eq 0;
        $handle->flush;
    }
}
#
# method to pull something off the queue
#
sub dequeue {
    my($self)=@_;
    my($header,$data);
    my($toread)=4;
    my($bytes_read)=0;
    my($handle)=$self->{'READER'};
    # read 4 byte header
    while ($bytes_read < $toread) {
       my $rv=read($handle,$header,$toread);
       die "read error : $!" unless defined $rv;
       die "read disconnected" if $rv eq 0;
       $bytes_read+=$rv;
    }
    $toread=unpack("N",$header);
    $bytes_read=0;
    # read the actual data
    while ($bytes_read < $toread) {
       my $rv=read($handle,$data,$toread,0);
       die "read error : $!" unless defined $rv;
       die "read disconnected" if $rv eq 0;
       $bytes_read+=$rv;
    }
    return $data;
}
#
# method to check if something can be dequeued
#
sub can_dequeue {
    my($self,$timeout)=@_;
    my($handle)=$self->{'READER'};
    if (defined(my $fileno = $handle->fileno())) {
        vec(my $rbit = '', $fileno, 1) = 1; # enable fd in vector table
        vec(my $ebit = '', $fileno, 1) = 1; # enable fd in vector table
        my $rv = select($rbit, undef, $ebit, $timeout); # select for readable handles
        die "can dequeue errors" if vec($ebit, $fileno, 1);
        return vec($rbit, $fileno, 1); # check fd in vector table
    } else { return undef; }
    # my($io) = IO::Select->new($handle);
    # return $io->can_read($timeout);
}
1;
#
#