package googscout;
use strict;

my $no_goog;

BEGIN {
    eval "use URI::Escape";    # utility functions for encoding the 
    if ($@) { $no_goog++};    # babelfish request
    eval "use LWP::UserAgent";
    if ($@) { $no_goog++};
}

sub forking_googscout {
    return '' if $no_goog;
   my ($direction, $lang, $phrase, $callback) = @_;
   $SIG{CHLD} = 'IGNORE';
   my $pid = eval { fork() };   # catch non-forking OSes and other errors
   return if $pid;              # parent does nothing
   $callback->(googscout());
   exit 0 if defined $pid;      # child exits, non-forking OS returns
}

sub googscout {
    
    my @cdata = `cat /usr/share/dict/american-english`;
    my $firstword = $cdata[int(rand($#cdata + 1))];
    my $secondword = $cdata[int(rand($#cdata + 1))];
    
    printf("First = $firstword");
    printf("Second = $secondword");
    my $command = $firstword . "+" . $secondword;
    my @wdata = system("lynx -dump -nolist http://www.google.com/search?q=$command&btnI=z");
    #printf @wdata;
}

googscout();



#my ($extract) = ($foo =~ m{([A-Za-z ]+peppery[A-Za-z ]+[.]) }sx);

#printf "foo results as $extract";

"Hello.  I'm a true value.";
