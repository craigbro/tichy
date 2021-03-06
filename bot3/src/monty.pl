# This program is copyright Jonathan Feinberg 1999.

# This program is distributed under the same terms as infobot.

# Jonathan Feinberg   
# jdf@pobox.com
# http://pobox.com/~jdf/

# Version 1.0
# First public release.

# Hacked on by JLB February 1st, 1900

package monty;
use strict;
use Socket;

my $no_monty;

BEGIN {
    eval "use URI::Escape";    # utility functions for encoding the 
    if ($@) { $no_monty++};    # montyfish request
    eval "use LWP::UserAgent";
    if ($@) { $no_monty++};
}

sub forking_monty {
    return '' if $no_monty;
   my ($message, $callback) = @_;
   $SIG{CHLD} = 'IGNORE';
   my $pid = eval { fork() };   # catch non-forking OSes and other errors
   return if $pid;              # parent does nothing
   $callback->(monty($message));
   exit 0 if defined $pid;      # child exits, non-forking OS returns
}

sub monty {
    return '' if $no_monty;
    my ($phrase) = @_;
    
    my $ua = new LWP::UserAgent;
    $ua->timeout(6);
    my ($buf, $line);

    my $server = "prep.onshored.com";
    my $port = 14303;
    my ($iaddr, $paddr, $proto);

    $iaddr = inet_aton($server);
    $paddr = sockaddr_in($port, $iaddr);
    $proto = getprotobyname('tcp');
    socket(SOK, PF_INET, SOCK_STREAM, $proto) or return;
    connect(SOK, $paddr) or return;
    select(SOK); $| = 1;
    print SOK "$phrase\n";
    select(STDOUT);

    while (1) {
	if (sysread(SOK,$buf,1) <= 0) {
	    last;
	}
	if ($buf=~/\n/) {
	    $line.=$buf;
	    return $line;
	} else {
	    $line.=$buf;
	}
    }
}
  
"Hello.  I'm a true value.";
