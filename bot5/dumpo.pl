#! /bin/perl

sub status () {
    my ($string) = @_;
    print $string . "\n";
}

require "src/DBM.pl";

%dbs = ("is" => "/home/opus/bot/opus-is.db",
	"are" => "/home/opus/bot/opus-are.db");

&openDBM(%dbs);
print "db: " . &showdb("is", "su");
