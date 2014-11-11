#!/usr/bin/perl

# you will probably need to change $homedir
# and possibly the path to perl above

my $homedir = '/home/opus/bot2';
my @ps = `ps auxw`;


    print "trying to run new process\n";
    chdir($homedir) || die "can't chdir to $homedir";
    system("nohup $homedir/infobot > /dev/null &");

