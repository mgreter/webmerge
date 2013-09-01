# from http://www.perlmonks.org/?node_id=49335
# 26.06.2012 added can_dequeue function (mgr@rtp.ch)
package Fork::Queue;
use IO::Socket;
#use IO::Select;

use strict;
use warnings;

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
    my $creator=IO::Socket->new() or die();
    my($reader,$writer);
    ($reader,$writer)=$creator->socketpair(AF_UNIX,SOCK_STREAM,PF_UNSPEC);
    shutdown($reader,1);
    shutdown($writer,0);
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
        print $handle $buffer;
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
       $bytes_read+=read($handle,$header,$toread,$bytes_read);
    }
    $toread=unpack("N",$header);
    $bytes_read=0;
    # read the actual data
    while ($bytes_read < $toread) {
       $bytes_read+=read($handle,$data,$toread,$bytes_read);
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
        select($rbit, undef, undef, $timeout); # select for readable handles
        return vec($rbit, $fileno, 1); # check fd in vector table
    } else { return undef; }
    # my($io) = IO::Select->new($handle);
    # return $io->can_read($timeout);
}
1;
#
#