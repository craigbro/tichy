# infobot :: Kevin Lenzo 1997-1999

# process the incoming message

$SIG{'ALRM'} = 'TimerAlarm';

sub process {
    ($who, $msgType, $message) = @_;
    $origMessage = $message;
    $message =~ s/[\cA-\c_]//ig; # strip control characters

    $addressed = 0;

    return if $instance =~ /antihelp/;

    my ($n, $uh) = ($nuh =~ /^([^!]+)!(.*)/);
    if ($param{'VERBOSITY'} > 3) { # murrayb++
      &status("Splitting incoming address into $n and $uh");
    }

    if ($msgType =~ /private/ and $message =~ /^hey, what is/) {
	$infobots{$nuh} = $who;
	&msg($who, "inter-infobot communication now requires version 0.43 or higher.");
	return 'NOREPLY';
    }

    return 'NOREPLY' if $message =~ /^...but/;
    return 'NOREPLY' if $message =~ /^.* already had it that way/;
    return 'NOREPLY' if $message =~ /^told /; # reply from friendly infobot
    return 'NOREPLY' if $message =~ /^told /; # reply from friendly infobot
    return 'NOREPLY' if ($message =~ /^[!\*]/);
    return 'NOREPLY' if ($message =~ /^gotcha/i);

    # this assumes that the ignore list will be fairly small, as we
    # loop through each key rather than doing a straight lookup

    if ($ignoreList{$uh} or $ignoreList{$who}) {
	  &status("IGNORE <$who> $message");
	  return 'NOREPLY';
    }

    foreach (keys %ignoreList) {
	my $ignoreRE = $_;
	my @parts = split /\*/, "a${ignoreRE}a";
	my $recast = join '\S*', map quotemeta($_), @parts;
	$recast =~ s/^a(.*)a$/$1/;
	if ($nuh =~ /^$recast$/) {
	    &status("IGNORE <$who> $message");
	    return 'NOREPLY';
	}
    }

    return 'NOREPLY' if (lc($who) eq lc($param{'nick'}));

    if ($msgType =~ /private/ and $message =~ s/^:INFOBOT://) {
	&status("infobot <$nuh> identified") unless $infobots{$nuh};
	$infobots{$nuh} = $who;
    }

    if ($infobots{$nuh}) {
	if ($msgType =~ /private/) {
	    if ($message =~ /^QUERY (<.*?>) (.*)/) {
		my $r;
		my $target = $1;
		my $item = $2;
		$item =~ s/[.\?]$//;
		
		&status(":INFOBOT:QUERY $who: $message");

		if ($r = &get("is", $item)) {
		    &msg($who, ":INFOBOT:REPLY $target $item =is=> $r");
		} 
		if ($r = &get("are", $item)) {
		    &msg($who, ":INFOBOT:REPLY $target $item =are=> $r");
		}
		return 'NOREPLY';
	    } elsif ($message =~ /^REPLY <(.*?)> (.*)/) {
		my $r;
		my $target = $1;
		my $item = $2;


		&status(":INFOBOT:REPLY $who: $message");

		my ($X, $V, $Y) = $item =~ /^(.*?) =(.*?)=> (.*)/;
		if (($param{'acceptUrl'} !~ /REQUIRE/) or ($Y =~ /(http|ftp|mailto|telnet|file):/)) {
		    &set($V, $X, $Y);
		    &msg($target, "$who knew: $X $V $Y");
		}

		return 'NOREPLY';
	    }

	} else {
	    return 'NOREPLY';
	}
    }

    $VerifWho = &verifyUser($nuh);

    if ($VerifWho) {
        if (IsFlag("i") eq "i") {
             &status("Ignoring $who: $VerifWho");
             return 'NOREPLY';
        }

	if ($msgType =~ /private/) {
	    # it's a private message
	    my ($potentialPass) = $message =~ /^\s*(\S+)/;

	    if (exists($verified{$VerifWho})) {
		# aging. you need to keep talking to it re-verify
		if (time() - $verified{$VerifWho} < 60*60) { # 1 hour decay
		    $verified{$VerifWho} = $now;
		} else {
		    &status("verification for $VerifWho expired");
		    delete $verified{$VerifWho};
		}
	    }

	    if ($uPasswd eq "NONE_NEEDED") {
		&status("no password needed for $VerifWho");
		$verified{$verifWho} = $now;
	    }

	    if (&ckpasswd($potentialPass, $uPasswd)) {
		$message =~ s/^\s*\S+\s*//;
		$origMessage =~ s/^\s*\S+\s*/<PASSWORD> /;
		&status("password verified for $VerifWho");
		$verified{$VerifWho} = $now;
		if ($message =~ /^\s*$/) {
		    &msg($who, "i recognize you there");
		    return 'NOREPLY';
		}
	    }
	}
    }

    # see User.pl for the "special" user commands
    return 'NOREPLY' if &userProcessing() eq 'NOREPLY';

    if ($msgType !~ /public/) { $addressed = 1; }

    if ($message =~ /^\s*$param{'nick'}\s*\?*$/i) {
	&status("feedback addressing from $who");
	$addressed = 1;
	$blocked = 0;	   
	if ($msgType =~ /public/) {
	    if (rand() > 0.5) {
		&performSay("yes, $who?");
	    } else {
		&performSay("$who?");
	    }
	} else {
	    &msg($who, "yes?");
	}

	$lastaddressedby = $who;
	$lastaddressedtime = time();
	return '';
    }

    if (($message =~ /^\s*$param{'nick'}\s*([\,\:\> ]+) */i) 
	or ($message =~ /^\s*$param{'nick'}\s*-+ *\??/i)) {
	# i have been addressed!
	my($it) = $&;

	if ($' !~ /^\s*is/i) {
	    $message = $';
	    $addressed = 1;
	    $blocked = 0;   
	}
    }

    if ($message =~ /, ?$param{nick}(\W+)?$/i) { # i have been addressed!
	my($it) = $&; 
	if ($` !~ /^\s*i?s\s*$/i) {
	    $xxx = quotemeta($it);
	    $message =~ s/$xxx//;
	    $addressed = 1;
	    $blocked = 0;   
	}
    }


    if ($addressed) {
	&status("$who is addressing me");
	$lastaddressedby = $who;
	$lastaddressedtime = time();

	if ($message =~ /^showmode/i ) {
	    if ($msgType =~ /public/) {
		if (($param{'addressing'} eq 'REQUIRE') && !$addressed) {
		    return "NOREPLY";
		} else {
		    &performSay ($who.", addressing me is currently in $param{addressing} mode.");
		    return "NOREPLY";
		}
	    } else {
		&msg($who, "addressing me is currently in $param{addressing} mode");
		return "NOREPLY";
	    }
	}
	
	my $channel = &channel();

    } else {
	my ($now, $diff);
	$now = time();
	$diff = $now - $lastaddressedtime;
	if ($who eq $lastaddressedby and $diff < 10) {
	    # assume we're talking to the same person even if we're
	    # not addressed, if we've been addressed in 10 seconds 
	    $addressed = 1;
	    &status("assuming continuity of address by $who ($diff seconds elapsed)");
	}
    }

    if ($addressed and $message =~ m|^\s*(.*?)\s+=~\s+s\/(.+?)\/(.*?)\/([a-z]*);?\s*$|) {
	# substitution: X =~ s/A/B/

	my ($X, $oldpiece, $newpiece, $flags) = ($1, $2, $3, $4);
	my $matched = 0;
	my $subst = 0;
	my $op = quotemeta($oldpiece);
	my $np = $newpiece;
	$X = lc($X);

	foreach $d ("is","are") {
	    if ($r = get($d, $X)) { 
		my $old = $r;
		$matched++;
		if ($r =~ s/$op/$np/i) {
		    if (length($r) > $param{maxDataSize}) {
			if ($msgType =~ /private/) {
			    &msg($who, "That's too long, $who");
			} else {
			    &say("That's too long, $who");
			}
			return 'NOREPLY';
		    }
		    set($d, $X, $r);
		    &status("update: '$X =$d=> $r'; was '$old'");
		    $subst++;
		}
	    }
	}
	if ($matched) {
	    if ($subst) {
		if ($msgType =~ /private/) {
		    &msg($who, "OK, $who");
		} else {
		    &say("OK, $who");
		}
		return 'NOREPLY';
	    } else {
		if ($msgType =~ /private/) {
		    &msg($who, "That doesn't contain '$oldpiece'");
		} else {
		    &say("That doesn't contain '$oldpiece', $who");
		}
	    }
	} else {
	    if ($msgType =~ /private/) {
		&msg($who, "I didn't have anything matching '$X'");
	    } else {
		&say("I didn't have anything matching '$X', $who");
	    }
	}
    }

    if ($addressed and IsFlag("S")) {
	if ($message =~ s/^\s*say\s+(\S+)\s+(.*)//) {
	    &msg($1, $2);
	    &msg($who, "ok.");
	    return 'NOREPLY';
	}
    }

    if ($message =~ s/^forget\s+((a|an|the)\s+)?//i) {
	# cut off final punctuation
	$message =~ s/[.!?]+$//;
	#return 'no authorization to lobotomize';
	#}
	$k = &normquery($message);
	$k = lc($k);

	$found = 0;

	foreach $d ("is", "are") {
	    if ($r = get($d, $k)) { 
		if (IsFlag("r") ne "r") {
		    performReply("you have no access to remove factoids");
		    return '';
		}
		$found = 1 ;
		&status("forget: <$who> $k =$d=> $r");
		clear($d, $k); 
		$factoidCount--;
	    }
	}
	if ($found == 1) {
	    if ($msgType !~ /public/) {
		&msg($who, "$who: I forgot $k");
	    } else {
		&say("$who: I forgot $k");
	    }
	    $l = $who; $l =~ s/^=//;
	    $updateCount++;
	    return '';
	} else {
	    if ($msgType !~ /public/) {
		&msg($who, "I didn't have anything matching $k");
		return '';
	    } else {
		if ($addressed > 0) {
		    &say("$who, I didn't have anything matching $k");
		    return '';
		}
	    }
	}
    }


    # Aldebaran++ !
    if ($param{"shutup"} and $message =~ /^\s*wake\s*up\s*$/i ) {
	if ($msgType =~ /public/) {
	    if ($addressed) {
		if (rand() > 0.5) {
		    &performSay("Ok, ".$who.", I'll start talking.");
		    &status("Changing to Optional mode");
		    $param{'addressing'} = 'OPTIONAL';
		    return "NOREPLY";
		} else {
		    &performSay(":O");
		    return "NOREPLY";
		}
	    }
	} else {
	    &msg($who, "OK, I'll start talking.");
	    $param{'addressing'} = 'OPTIONAL';
	    &status("Changing to Optional mode");
	    return "NOREPLY";
	}
    }
 
    if ($param{"shutup"} and $message =~ /^\s*shut\s*up\s*$/i ) {
	if ($msgType =~ /public/) {
	    if ($addressed) {
		if (rand() > 0.5) {
		    &performSay("Sorry, ".$who.", I'll keep my mouth shut. ");
		    $param{'addressing'} = 'REQUIRE';
		    &status("Changing to Require mode");
		    return "NOREPLY";
		} else {
		    &performSay(":X");
		    return "NOREPLY";
		}
	    } 
	} else {
	    &msg($who, "Sorry, I'll try to be quiet.");
	    $param{'addressing'} = 'REQUIRE';
	    &status("Changing to Require mode");
	    return "NOREPLY";
	}
    }

    $target = $who;

    $skipReply = 0;
    $message_input_length = length($message);

    foreach $x (@confused) {
	$y = quotemeta($x);
	return "" if $message =~ /^\s*$y\s*/;
    }

    return if ($who eq $param{'nick'});

    $message =~ s/^\s+//;	# strip any dodgey spaces off

    if (($message =~ s/^\S+\s*:\s+//) or ($message =~ s/^\S+\s+--+\s+//)) {
	# stripped the addressee ("^Pudge: it's there")
	$reallyTalkingTo = $1;
    } else {
	$reallyTalkingTo = '';
	if ($addressed) {
	    $reallyTalkingTo = $param{'nick'};
	}
    }

    # here's where the external routines get called.
    # if they return anything but null, that's the "answer".
    my $mr = &myRoutines();

    if ($mr =~ /\S/) {
	&status("myRoutines: $mr");
	return $mr;
    }

    # might want to take this out.

    if ($message =~ /^seen (\S+)/) {
	my $person = $1;
	$person =~ s/\?*\s*$//;
	if ($seen{lc $person}) {
	    my ($when,$what) = split /$;/, $seen{lc $person};
	    my $howlong = time() - $when;
	    $when = localtime $when;

	    my $tstring = ($howlong % 60). " seconds ago";
	    $howlong = int($howlong / 60);
	    
	    if ($howlong % 60) {
		$tstring = ($howlong % 60). " minutes and $tstring";
	    }
	    $howlong = int($howlong / 60);

	    if ($howlong % 24) {
		$tstring = ($howlong % 24). " hours, $tstring";
	    }
	    $howlong = int($howlong / 24);

	    if ($howlong % 365) {
		$tstring = ($howlong % 365). " days, $tstring";
	    }
	    $howlong = int($howlong / 365);
	    if ($howlong > 0) {
		$tstring = "$howlong years, $tstring";
	    }
	    
	    if ($msgType =~ /public/) {
		&performSay("$person was last seen on IRC $tstring, saying: $what [$when]");
	    } else {
		&msg($who, "$person was last seen on IRC $tstring, saying: $what [$when]");
	    }
	    return 'NOREPLY';
	}
	
	if ($msgType =~ /public/) {
	    &performSay("I haven't seen '$person', $who");
	} else {
	    &msg($who,"I haven't seen '$person', $who");
	}
	return 'NOREPLY';
    }

    if ($message =~ /^\s*heya?,? /) {
	return unless $addressed;
	# greetings
    }

    # Gotta be gender-neutral here... we're sensitive to purl's needs. :-)
    if ($message =~ /(good( fuckin['g]?)? (bo(t|y)|g([ui]|r+)rl))|(bot( |\-)?snack)/i) {
	&status("random praise");
	if ($msgType =~ /public/) {
	    if ((time() - $prevTime <= 15) || ($addressed)) {
		if (rand()  < .5)  {
		    &performSay("thanks $who :)");
		} else {
		    &performSay(":)");
		}
	    }
	} else {
	    &msg($who, ":)");
	}
	return "";
    }

    if ($addressed) {
	if ($message =~ /you (rock|rocks|rewl|rule|are so+ co+l)/) {
	    if (rand()  < .5)  {
		&performSay("thanks $who :)");
	    } else {
		&performSay(":)");
	    }
	    return "";
	}
	if ($message =~ /thank(s| you)/i) {
	    if ($msgType =~ /public/) {
		if (rand()  < .5)  {
		    &performSay($welcomes[int(rand(@welcomes))]." ".$who);
		} else {
		    &performSay($who.": ".$welcomes[int(rand(@welcomes))]);
		}
	    } else {
		if (rand()  < .5)  {
		    &msg($who, $welcomes[int(rand(@welcomes))].", ".$who);
		} else {
		    &msg($who, $welcomes[int(rand(@welcomes))]);
		}
	    }
	    return "";
	}
    }

    if ($message =~ /^\s*(h(ello|i( there)?|owdy|ey|ola)|salut|bonjour|niihau|que\s*tal)( $param{nick})?\s*$/i) {
	if (!$addressed and rand() > 0.35) {
	    # 65% chance of replying to a random greeting when not addressed
	    return "";
	}

	my($r) = $hello[int(rand(@hello))];
	if ($msgType =~ /public/) {
	    &performSay($r.", $who");
	} else {
	    &msg($who, $r);
	}
	return "";
    }

    if (($message =~ /^nslookup (\S+)$/i) and $param{allowDNS}) {
	&status("DNS Lookup: $1");
	&DNS($1);
	return '';
    }

    if ($param{ispell} and ($message =~ s/^spell(ing)? (?:of|for )?//)) {
        &ispell($message);
        return '';
    }

    if (($message =~ /^traceroute (\S+)$/i) and $param{allowTraceroute}) {
	&status("traceroute to $1");
	&troute($1);
	return '';
    }

    if ($message =~ /^crypt\s*\(\s*(\S+)\s*(?:,| )\s*(\S+)/) {
	my $cr = crypt($1, $2);
	if ($msgType =~ /private/) {
	    &msg($who, $cr);
	} else {
	    &performSay($cr);
	}
	return '';
    }

    if (($message =~ /^internic (\S+)$/i) and $param{allowInternic}) {
	&status("internic whois query: $1");
	&domain_summary($1);				
	return '';
    }

    $message =~ s/^\s*hey,?\s+where/where/i;
    $message =~ s/whois/who is/ig;
    $message =~ s/where can i find/where is/i;
    $message =~ s/how about/where is/i;
    $message =~ s/^(gee|boy|golly|gosh),? //i;
    $message =~ s/^(well|and|but|or|yes),? //i;
    $message =~ s/^(does )?(any|ne)(1|one|body) know //i;
    $message =~ s/ da / the /ig;
    $message =~ s/^heya?,?( folks)?,*\.* *//i; # clear initial filled pauses & stuff
    $message =~ s/^[uh]+m*[,\.]* +//i;
    $message =~ s/^o+[hk]+(a+y+)?,*\.* +//i; 
    $message =~ s/^g(eez|osh|olly)+,*\.* +(.+)/$2/i;
    $message =~ s/^w(ow|hee|o+ho+)+,*\.* +(.+)/$2/i;
    $message =~ s/^still,* +//i; 
    $message =~ s/^well,* +//i;
    $message =~ s/^\s*(stupid )?q(uestion)?:\s+//i;

    # may not want to cut off all: all i know is ... 
    # but for now seem mostly content-free

    if ($param{'allowLeave'} =~ /$msgType/) {
	if ($message =~ /(leave|part) ((\#|\&)\S+)/i) {
	    if (IsFlag("o") or $addressed) {
		if (IsFlag("c") ne "c") {
		    &performReply("you don't have the channel flag");
		    return '';
		}
		&channel($2);
		&performSay("goodbye, $who.");
		&status("PART $2 <$who>");
		&part($2);
		return '';
	    }
	}
    }

    if ($msgType !~ /public/) {
	# accept only msgs leaves/joins
	my($ok_to_join);
        if ($message =~ /join ([&#]\S+)(?:\s+(\S+))?/i) {
            # Thanks to Eden Li (tile) for the channel key patch
            my($which, $key) = ($1, $2);
            $key = defined ($key) ? " $key" : "";
	    foreach $chan (split(/\s+/, $param{'allowed_channels'})) {
		if (lc($which) eq lc($chan)) {
		    $ok_to_join = $which . $key;
		    last;
		}
	    }
	    if (IsFlag("o")) { $ok_to_join = $which.$key };
	    if ($ok_to_join) {
		if (IsFlag("c") ne "c") {
		    &msg($who, "You don't have the channel flag");
		    return '';
		}
		joinChan($ok_to_join);
		&status("JOIN $ok_to_join <$who>");
		&msg($who, "joining $ok_to_join") 
		    unless ($channel eq &channel());
		sleep(1);
				# my $temp = &channel();
				# &performSay("hello, $who.");
				# &channel($temp);
		return '';
	    } else {
		&msg($who, "I am not allowed to join that channel.");
		return '';
	    }
	}
    }

    if (($message =~ s/^(no,?\s+$param{'nick'},?\s*)//i)
	or ($addressed and $message =~ s/^(no,?\s+)//i)) { 
        # clear initial negative
	# an initial negative may signify a correction
	$correction_plausible = 1;
	&status("correction is plausible, initial negative and nick deleted ($1)") if ($param{VERBOSITY} > 2);
    } else {
	$correction_plausible = 0;
    }

    my($result) = "";

    my $holdMessage = $message;

    $result = &doQuestion($msgType, $message) 
	unless ($who eq 'NOREPLY');
    
    if (($result eq 'NOREPLY') or ($who eq 'NOREPLY')) {
	return '';
    }

    if ($result) {
	if (($param{'addressing'} eq "REQUIRE") and !$addressed) {
	    return 'NOREPLY';
	}
	if (!$finalQMark and !$addressed and 
	    ($input_message_length < $param{'minVolunteerLength'})) {
	    $in = '';
	    return 'NOREPLY';
	}
    }
    
    if ($result !~ /^\s*$/) {
	&status("question: <$who> $message");

	$questionCount++;

	if ($msgType =~ /public/) {
	    if (!$target or !$answer or ($who eq $target)) {
		if ($result) {
		    &performSay($result) unless $blocked;
		} else {
		    &performSay("i didn't have anything matching $tell_obj, $who");
		}
	    } else {
		my $r = "$who wants you to know: $result";
		&msg($target, $r);
		if ($who ne $target) {
		    &msg($who, "told $target about $tell_obj ($r)");
		}
		return 'NOREPLY';
	    }
	} else {		# not public
	    $l = $who;
	    $l =~ s/=//g;
	    if ($answer ne "" ) { # a real answer
		if ($who eq $target) {
		    &msg($who, $result);
		} else {	# to someone else
		    my $r;

		    if ($who eq $target) {
			&msg($target, $result);
		    } else {
			$r = "$who wants you to know: $result";
			&msg($target, $r);
			&msg($who, "told $target about $tell_obj ($r)");
		    }
		}
	    } else {		# didn't know
		&msg($who,$result);
	    }
	}
    } else {			# no reply from doQ
	return "No authorization to teach" unless (IsFlag("t") eq "t");
	if (!$param{'allowUpdate'}) {
	    return '';
	}

	$result = &doStatement($msgType, $holdMessage);

	if (($who eq 'NOREPLY')||($result eq 'NOREPLY')) { return ''; };

	return 'NOREPLY' if grep $_ eq $who, split /\s+/, $param{friendlyBots};

	if ($result !~ /^\s*$/) {
	    if ($msgType !~ /public/) { 
		&msg($who, "gotcha.")
		}
	} else {
	    if ($msgType !~ /public/) { 
		&msg($who, $confused[int(rand(@confused))]);
	    }
	    if (($msgType !~ /public/) || ($addressed)) {
		&status("unparseable: $message");
	    }
	}
    }
}

1;
