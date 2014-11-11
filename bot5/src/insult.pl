#!/usr/bin/perl

my $no_insult;

BEGIN {
    eval "use Net::Telnet ();";
    $no_insult++ if ($@) ;
}

sub insult {
    my $t = new Net::Telnet (Timeout => 3);
    $t->Net::Telnet::open(Host => "insulthost.colorado.edu", Port => "1695");
    my $line = $t->Net::Telnet::getline(Timeout => 4);
    return $line;
}

1;
