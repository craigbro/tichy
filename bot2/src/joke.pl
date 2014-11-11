# This program is copyright Jonathan Feinberg 1999.

# This program is distributed under the same terms as infobot.

# Jonathan Feinberg   
# jdf@pobox.com
# http://pobox.com/~jdf/

# Version 1.0
# First public release.

# Hacked on by JLB February 1st, 1900

package joke;
use strict;

my $jq = '';
my $ja = '';

sub joke_q {
    my $len = `cat /home/opus/dumbjokes.txt | wc -l`;
    my $jokenum = int(rand ($len / 2));
    
    if (open (COMMENTS, "</home/opus/dumbjokes.txt")) {
	my $num = 0;
	while (<COMMENTS>) {
	    if ($num == ($jokenum * 2)) {
		$jq = $_;
	    };
	    if ($num == (1 + ($jokenum * 2))) {
		$ja = $_;
		return $jq;
	    }
	    $num++;
	}
    }
}

sub joke_a {
    my $text;
    $text = $ja;
    $jq = '';
    $ja = '';
    return $text;
}

"Hello.  I'm a true value.";
