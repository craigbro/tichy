# WWWSearch backend, with queries updating the is-db (optionally)
# Uses WWW::Search::Google and WWW::Search
# originally Google.pl, drastically altered.

use strict;

package W3Search;

my @engines;
my $no_W3Search;

BEGIN {
    $no_W3Search = 0;
    eval "use WWW::Search";
    $no_W3Search++ if $@;
    eval "use WWW::Search::Google";
    $no_W3Search++ if $@;
    @engines = qw(AltaVista Dejanews Excite Gopher HotBot Infoseek 
		     Lycos Magellan PLweb SFgate Simple Verity Google);
    $W3Search::regex = join '|', @engines;
}

sub forking_W3Search {
    if ($no_W3Search) {
	&main::status("W3Search: this requires WWW::Search::Google to operate.");
	return '';
    }

    my ($where, $what, $type, $callback) = @_;
    $SIG{CHLD} = 'IGNORE';
    my $pid = eval { fork() };   # catch non-forking OSes and other errors
    return 'NOREPLY' if $pid;              # parent does nothing
    $callback->(W3Search($where, $what, $type));
    exit 0 if defined $pid;      # child exits, non-forking OS returns
}

sub W3Search {
    if ($no_W3Search) {
	&status("WWW search requires WWW::Search and WWW::Search::Google");
	return 'sorry, can\'t do that';
    } else {
	my ($where, $what, $type) = @_;

	my @matches = grep { lc($_) eq lc($where) ? $_ : undef } @engines;
	if (!@matches) {
	    return "i don't know how to check '$where'";
	} else {
	    $where = shift @matches;
	}

	my $Search = new WWW::Search($where);
	my $Query = WWW::Search::escape_query($what);
	$Search->native_query($Query); 

	my ($Result, $r, $count);
	while ($r = $Search->next_result()) {
	    if ($Result) {
		$Result .= " or ".$r->url();
	    } else {
		$Result = $r->url();
	    }
	    last if ++$count >= 3;
	}
	
 	if ($Result) {
	    if ($type =~ /update/) {
		$main::correction_plausible++ if $type =~ /force/i;
		$main::addressed++;
		$main::googling = 1;
		&main::update($what, "is", $Result);
		$main::googling = 0;
	    }
	    return "$where says $what is $Result";
	} else {
	    return "$where can't find $what";
	}
    }
}

1;
