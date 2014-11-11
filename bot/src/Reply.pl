# infobot :: Kevin Lenzo   (c) 1997

sub getReply {
    my($msgType, $message) = @_;
    my($theMsg) = "";
    my($locMsg) = $message;

    # x is y

    # x    is the lhs (left hand side)
    # 'is' is the mhs ("middle hand side".. the "head", or verb)
    # y    is the Y (right hand side)

    my($X, $V, $Y, $result);
    my ($theVerb, $orig_Y);

    $locMsg =~ tr/A-Z/a-z/;

    if ($result = get("is", $locMsg)) {
	&status("exact: $message =is=> $result");
	$theVerb = "is";
	$X = $message;
	$V = $theVerb;
	$Y = $result;
	$orig_Y = $X;

    } elsif ($result = get("are", $locMsg)) {
	&status("exact: $message =is=> $result");
	$theVerb = "are";
	$X = $message;
	$V = $theVerb;
	$Y = $result;
	$orig_Y = $X;

    } else {
	$y_determiner = '';
	$verbs = join '|', @verb;

	$message = " $message ";

	if ($message =~ / ($verbs) /i) {
	    $X = $`;
	    $V = $1; 
	    $Y = $';

	    $X =~ s/^\s*(.*?)\s*$/$1/;
	    $Y =~ s/^\s*(.*?)\s*$/$1/;
	    $orig_Y = $Y;
	    $Y =~ tr/A-Z/a-z/;

	    $V =~ s/^\s*(.*?)\s*$/$1/;

	    if ($Y =~ s/^(an?|the)\s+//) {
		$y_determiner = $1;
	    } else {
		$y_determiner = '';
	    }

	    if ($questionWord !~ /^\s*$/) {
		if ($V eq "is") {
		    $result = &get("is", $Y);
		} else {
		    if ($V eq "are") {
			$result = &get("are", $Y);
		    }
		}
	    }
	    $theVerb = $V;
	}

	if ($param{'VERBOSITY'} > 1) {
	    my $debugstring = "\tmsgType:\t$msgType\n";
	    $debugstring .= "\tquestionWord:\t$questionWord\n";
	    $debugstring .= "\taddressed:\t$addressed\n";
	    $debugstring .= "\tfinalQMark:\t$finalQMark\n";
	    $debugstring .= "\tX[$X] verb[$theVerb] det[$y_determiner] Y[$Y]\n";
	    $debugstring .= "\tresult:\t$result\n";
	    &status($debugstring);
	}

	if ($y_determiner) {
	    # put the det back on 
	    $Y = "$y_determiner $Y";
	}

	# search imdb
	if ($locMsg =~ s/^\s*(search )?imdb (for )?//) {
	    $check = $locMsg;
	    my $url = $locMsg;

	    # freeside++ for URL cleanup code

	    my $date = "";
	    if ($url =~ s/( \(\d+\))$//) { $date = $1; }
	    $url =~ s/^(The|A|An|Les) (.*)/$2, $1/i;
	    $url = "http://www.imdb.com/M/title-substring?title=$url$date&type=fuzzy";
	    $url =~ s/ /+/g;
	    $V = "-> "; $orig_lhs = $locMsg; $theVerb= "is";
	    return "$locMsg can be found at $url";
	}

	if ($locMsg =~ s/^\s*(search )?hyperarchive (for )?//) {
	    $locMsg =~ /\w+/;
	    $check = $locMsg;
	    my $q = $locMsg;
	    $q =~ s/\W+//g;
	    $result = "http://hyperarchive.lcs.mit.edu/cgi-bin/NewSearch?key=$q";
	    $V = "-> "; $orig_lhs = $locMsg; $theVerb= "is";
	    return "$locMsg may be sought at $result";
	}

	# websters
	if ($locMsg =~ s/^\s*(search )?websters? (for )?//) {
	    $locMsg =~ /\w+/;
	    $word = $&;
	    $check = $locMsg;
	    my $q = $locMsg;
	    $q =~ s/\W+/+/g;
	    $result = "http://work.ucsd.edu:5141/cgi-bin/http_webster?$word";
	    $V = "-> "; $orig_lhs = $locMsg; $theVerb= "is";
	    return "$locMsg may be sought at $result";
	}
# check "is" tables anyway for lhs alone

	if (!defined($V)) {	# no explicit head had been found
	    my $det;
	    if ($locMsg =~ s/^\s*(an?|the)\s+//) {
		$det = $1;
	    }
	    $locMsg =~ s/[.!?]+\s*$//;

	    my($check) = "";

	    $check = &get("is", $locMsg);

	    if ($check ne "") {
		$result = $check;
		$orig_Y = $locMsg;
		$theVerb = "is";
		$V = "is";	# artificially set the head to is
	    } else {
		$check = &get("are", $locMsg);
		if ($check ne "") {
		    $result = $check;
		    $V = "are"; # artificially set the head to are
		    $orig_Y = $locMsg;
		    $theVerb = "are";
		}
	    }
	    if ($det) {
		$orig_Y = "$det $orig_Y";
	    }
	}

    }

    if ($V ne "") {		# if there was a head...
	my(@poss) = split("\\|", $result);
	$poss[0] =~ s/^\s//;
	$poss[$#poss] =~ s/\s$//;

	if ((@poss > 1) && ($msgType =~ /public/)) {
	    $theMsg = $poss[int(rand(@poss))];
	    $theMsg =~ s/^\s*//;
	} else {
	    $theMsg = $result;
	}
    }

    $skipReply = 0;

    if ($theMsg ne "") {
	if ($msgType =~ /public/) {
	    my $interval = time() - $prevTime;
	    if ( ($param{'mode'} eq 'IRC' ) 
		&& $param{'repeatIgnoreInterval'}
		&& ($theMsg eq $prevMsg) 
		&& ((time()-$prevTime) < $param{'repeatIgnoreInterval'})) {
		&status("repeat ignored ($interval secs < $param{'repeatIgnoreInterval'})");
		$skipReply = 1;
		$theMsg = "NOREPLY";
		$prevTime = time();
	    } else {
		$skipReply = 0;
		$prevTime = time() unless ($theMsg eq $prevMsg);
		$prevMsg = $theMsg;
	    }
	}


	# by now $theMsg should contain the result, or null

	# this global is nto a great idea
	$shortReply = 0;
        $noReply = 0;
       
	if (0 and $theMsg =~ s/^\s*<noreply>\s*//i) { 
	    # specially defined type. No reply. Experimental.
	    $noReply = 1;
	    return 'NOREPLY';
	}

	if (!$msgType) {
	    $msgType = 'private';
	    &status("NO MSG TYPE / set to private\n");
	}

	if ($msgType !~ /private/ and $theMsg =~ s/^\s*<reply>\s*//i) {
	    # specially defined type.  only remove '<reply>'
	    $shortReply = 1;
	} elsif ($msgType !~ /private/ and $theMsg =~ s/^\s*<action>\s*(.*)/\cAACTION $1\cA/i) {
	    # specially defined type.  only remove '<action>' and make it an action
	    $shortReply = 1;
	} else {		# not a short reply
	    if (!$infobots{$nuh} and $theVerb =~ /is/) {
		my($x) = int(rand(16));
		# oh this could be done much better
		if ($x <= 8) { 
		    $theMsg= "$orig_Y is $theMsg";
		}
		if ($x == 9) { 	
		    $theMsg= "$orig_Y is probably $theMsg";
		}
		if ($x == 10) { 
		    $theMsg= "rumour has it $orig_Y is $theMsg";
		}
		if ($x == 11) { 
		    $theMsg= "i heard $orig_Y was $theMsg";
		}
		if ($x == 12) { 
		    $theMsg= "somebody said $orig_Y was $theMsg";
		}
		if ($x == 13) { 
		    $theMsg= "i guess $orig_Y is $theMsg";
		}
		if ($x == 14) { 
		    $theMsg= "well, $orig_Y is $theMsg";
		}
		if ($x == 15) { 
		    $theMsg =~ s/[.!?]+$//;
		    $theMsg= "$orig_Y is, like, $theMsg";
		}
	    } else {
		$theMsg = "$orig_Y $theVerb $theMsg" if ($theMsg !~ /^\s*$/);
	    }
	}
    }

    my $safeWho = &purifyNick($who);

    if (!$shortReply) {
	# shouldn't this be in switchPerson?
	# this is fixing the person for going back out

# /^onz!lenzo@lenzo.pc.cs.cmu.edu privmsg rurl :*** noctcp: omega42 is/: nested *?+ in regexp at /usr/users/infobot/infobot-current/src/Reply.pl line 266, <FH> chunk 176.
	
	if ($theMsg =~ s/^$safeWho is/you are/i) { # fix the person 
	} else {
	    $theMsg =~ s/^$param{'nick'} is /i am /ig;
	    $theMsg =~ s/ $param{'nick'} is / i am /ig;
	    $theMsg =~ s/^$param{'nick'} was /i was /ig;
	    $theMsg =~ s/ $param{'nick'} was / i was /ig;

	    if ($addressed) {
		$theMsg =~ s/^you are (\.*)/i am $1/ig;
		$theMsg =~ s/ you are (\.*)/ i am $1/ig;
	    } else {
		if ($theMsg =~ /^you are / or $theMsg =~ / you are /) {
		    $theMsg = 'NOREPLY';
		}
	    }
	}

	$theMsg =~ s/ $param{'ident'}\'?s / my /ig;
	$theMsg =~ s/^$safeWho\'?s /$safeWho, your /i;
	$theMsg =~ s/ $safeWho\'?s / your /ig;
    }
    

    if (1) {			# $date, $time 
	$curDate = scalar(localtime());
	chomp $curDate;
	$curDate =~ s/\:\d+(\s+\w+)\s+\d+$/$1/;
	$theMsg =~ s/\$date/$curDate/gi;
	$curDate =~ s/\w+\s+\w+\s+\d+\s+//;
	$theMsg =~ s/\$time/$curDate/gi;
    }

    $theMsg =~ s/\$who/$who/gi;

    if (1) {			# variables. like $me or \me
	$theMsg =~ s/(\\){1,}([^\s\\]+)/$1/g;
    }

    $theMsg =~ s/^\s*//;
    $theMsg =~ s/\s+$//;

    if ($param{'filter'}) {
	require "src/filter.pl";
	$theMsg = &filter($theMsg);
    }
    $theMsg;
}

1;
