# Infobot user extension stubs 
# Kevin A. Lenzo

# put your routines in here.

do 'src/nickometer.pl'; # Adam Spier's "lame nick-o-meter" code

sub myRoutines {
    # called after it decides if it's been addressed.
    # you have access tothe global variables here, 
    # which is bad, but anyway.

    # you can return 'NOREPLY' if you want to stop
    # processing past this point but don't want 
    # an answer. if you don't return NOREPLY, it
    # will let all the rest of the default processing
    # go to it. think of it as 'catching' the event.

    # $addressed is whether the infobot has been 
    #			named or, if a private or standalone
    #			context, addressed is always 'true'

    # $msgType can be 'public', 'private', maybe 'dcc_chat'

    # $who is the sender of the message

    # $message is the current state of the input, after
    #		  the addressing stuff stripped off the name

    # $origMessage is the text of the original message before
    #			  any normalization or processing

    # you have access to all the routines in urlIrc.pl too,
    # of course.

    # example:

    if ($addressed) {
	# only if the infobot is addressed
	if ($message =~ /how (the hell )?are (ya|you)( doin\'?g?)?\?*$/) {
	    if ($msgType eq 'public') {
		&say($howAreYa[rand($#howAreYa)].", $who");
	    } else {
		&msg($who, $howAreYa[rand($#howAreYa)].", $who");
	    }
	    return 'NOREPLY';
	}
    } else {
	# we haven't been addressed, but we are still listening
    }

    # Spit out random historical murmuring, hiding identity of speaker - JLB

    if ($addressed && $message =~ /histor/)
    {
	if (open (COMMENTS, "</home/opus/bot/opus.log")) {
	    while (<COMMENTS>) {
		if (int(rand 70000) == 42) {
		    if (s/^.*> // > 0) {
			&say("$_");
			close COMMENTS;
			return 'NOREPLY';
		    }
		}
	    }
	}
    }

    # Impersonate another user

    if ($addressed && 
       $message =~ m{
                 ^\s*
                 impersonate
               \s*
               (.+)
              }xoi) {
	&say("I will be $1 for a while.");
	$faking = $1;
	return 'NOREPLY';
    }

    if ($message =~ m{
                 ^\s*
		     joke
               \s*
              }xoi) {
	&say(&joke::joke_q());
	return 'NOREPLY';
    }


    if ($message =~ /(dunno|know|give|clue)/) {
	&say(&joke::joke_a());
	return 'NOREPLY';
    }

    # utterance stat 1

    if ($addressed && 
       $message =~ m{
		     \s*
		 ([a-z]+)
		 \s*
                 said    
               \s*
               (.+)
              }xoi) {
	my @cdata;

	if ($1 == 'anyone') {
	    @cdata = `grep "<.*/.*$2" /home/opus/bot/opus.log`;
	} else {
	    @cdata = `grep "<$1/.*$2" /home/opus/bot/opus.log`;
	}
	&say("oh about " + $#cdata + " times");
	return 'NOREPLY';
    }

    # Spit out specific historical murmuring, hiding identity of speaker - JLB

    if ($addressed && 
       $message =~ m{
                 ^\s*
                 snifflog
               \s*
               (.+)
              }xoi) {           
	my @cdata = `grep $1 /home/opus/bot/opus.log`;
	$_ = $cdata[int(rand($#cdata + 1))];
	if (s/^(\d+)\s\[\d+\] <(.*)\/.*> // > 0) {
	    my $qdate, $qwho;
	    $qdate = localtime($1);
	    if (length($2) == 0) {
		$qwho = "Opus";
	    } else {
		$qwho = ucfirst($2);
	    }
	    &say("On $qdate, $qwho said \"$_\"");
	    close COMMENTS;
	    return 'NOREPLY';
	}
    }

    # Spit out chronicle - JLB

    if ($addressed && 
       $message =~ m{
                 ^\s*
                 recite
               \s*
               (.+)
              }xoi) {           
	my($check) = "";
	$check = &get("is", "chronicle of $1");
	if ($check ne "") {
	    &say("I speak the chronicle of $1, which is thus:");
	    my $part = 0;
	    
	    foreach (split / /, $check) {
		my $tries = 0;
		my @cdata = `grep $_ /home/opus/bot/opus.log`;
	      retry:
		$_ = $cdata[int(rand($#cdata + 1))];
		if (s/^(\d+)\s\[\d+\] <(.*)\/.*> // > 0) {
		    my $qdate, $qwho;
		    $qdate = localtime($1);
		    if (length($2) == 0) {
			$qwho = "Opus";
		    } else {
			$qwho = ucfirst($2);
		    }
		    &say("$_");
		} else {
		    $tries++;
		    if ($tries < 5) {
			goto retry;
		    }
		}
	    }
	}
    }
    

    # spit out random historical quote with date and credit the speaker - JRD

    if ($addressed && $message =~ /quote/)
    {
	if (open (COMMENTS, "</home/opus/bot/opus.log")) {
	    while (<COMMENTS>) {
		if (int(rand 70000) == 42) {
		    if (s/^(\d+)\s\[\d+\] <(.*)\/.*> // > 0) {
			my $qdate, $qwho;
			$qdate = localtime($1);
			if (length($2) == 0) {
			    $qwho = "Opus";
			} else {
			    $qwho = ucfirst($2);
			}
			&say("On $qdate, $qwho said \"$_\"");
			close COMMENTS;
			return 'NOREPLY';
		    }
		}
	    }
	}
    }
    # from Chris Tessone: slashdot headlines
    # "slashdot" or "slashdot headlines"
    if (defined($param{'slash'}) and $message =~
       /^\s*slashdot( headlines)?\W*\s*$/) {
      my $headlines = &getslashdotheads();
      if ($msgType eq 'public') {
        &say("$who: $headlines");
      } else {
        &msg($who, $headlines);
      }
      return "NOREPLY";
    } 

     # Jonathan Feinberg's babel-bot  -- jdf++
     if (defined $param{babel} && 
       (1 or $addressed) && 
       $message =~ m{
                 ^\s*
                 (?:babel(?:fish)?|x|xlate|translate)
                 \s+
		     (to|from|toandfro)   # direction of translation (through)
               \s+
               ($babel::lang_regex)\w*    # which language?
               \s*
               (.+)                # The phrase to be translated
              }xoi) {           
	 my $whom = $who;  # building a closure, need lexical
	 my $callback = $msgType eq 'public' ? 
	     sub{say("$who: $_[0]")} : sub{msg($who, $_[0])};
	 &babel::forking_babelfish(lc $1, lc $2, $3, $callback);
	 return 'NOREPLY';
     }

     # trigger some impromptu korean travesties - JLB
     if ($message =~ /ninja/)
     {
	 my $whom = $who;  # building a closure, need lexical
	 my $callback = $msgType eq 'public' ? 
	     sub{say("$who: $_[0]")} : sub{msg($who, $_[0])};
	 &babel::forking_babelfish('toandfro', 'ko', $message, $callback);
	 return 'NOREPLY';
     }

    # health improve
     if ($message =~ /snack/)
     {
         $health = $health + 1;
         my @cdata = `cat /home/opus/botsnack`;
         $_ = $cdata[int(rand($#cdata + 1))];
         &say($_);
     }
     # health deteriorate
     if ($message =~ /smack/)
     {
         $health = $health - 1;
         my @cdata = `cat /home/opus/botsmack`;
         $_ = $cdata[int(rand($#cdata + 1))];
         &say($_);
     }

     # release name
     if ($message =~ /release/)
     {
         my @cdata = `cat /home/opus/blah/release`;
         $_ = $cdata[int(rand($#cdata + 1))];
         &say($_);
     }

     # Mod to babel-bot to support Hungarian - JLB
     if (defined $param{magyar} && 
       (1 or $addressed) && 
       $message =~ m{
                 ^\s*
                 (?:babel(?:fish)?|x|xlate|translate)
                 \s+
		     (to|from)   # direction of translation (through)
               \s+
                 (magyar|hungarian)
               \s*
               (\w+)                # The phrase to be translated
              }xoi) {           
	 my $whom = $who;  # building a closure, need lexical
	 my $callback = $msgType eq 'public' ? 
	     sub{say("$who: $_[0]")} : sub{msg($who, $_[0])};
	 &magyar::forking_magyar(lc $1, lc $2, $3, $callback);
	 return 'NOREPLY';
     }

     # obscenity-enabled anagram generation - JLB
     if ($message =~ m{
             ^\s*
                 (anagram)
                     \s*
               (.+)                # The phrase to be mangled
               }xoi) {           
         my @cdata = `/home/opus/nastygram $2`;
         $_ = $cdata[0];
         &say($_);
     }

    # you can impersonate the bot! - JLB

     if (($msgType eq 'private') && ($message =~ m{
                 ^\s*
                 tell
                 \s+
		     ([a-zA-z0-9]+)
               \s*
               (.*)                # The phrase to be translated
              }xoi)) {           
	 &say("$1: $2");
	 return 'NOREPLY';
     }

     # Travlang dictionaries - JLB
     if (defined $param{travlang} && 
       (1 or $addressed) && 
       $message =~ m{
                 ^\s*
                 (?:babel(?:fish)?|x|xlate|translate)
                 \s+
		     (to|from)   # direction of translation (through)
               \s+
                 ($travlang::lang_regex)\w*
               \s*
               (\w+)                # The phrase to be translated
              }xoi) {           
	 my $whom = $who;  # building a closure, need lexical
	 my $callback = $msgType eq 'public' ? 
	     sub{say("$who: $_[0]")} : sub{msg($who, $_[0])};
	 &travlang::forking_travlang(lc $1, lc $2, $3, $callback);
	 return 'NOREPLY';
     }

    # insult server. patch thanks to michael@limit.org
    if ($param{'insult'} and ($message =~ /^\s*insult (.*)\s*$/)) {
	my $person = $1;
	my $language = "english";
	if ($person =~ s/ in \s*($babel::lang_regex)\w*\s*$//xi) {
	    $language = lc($1);
	}

 	my $insult = &insult();

	$person = $who if $person =~ /^\s*me\s*$/i;
	if ($person =~ /^\s*gracchus\s*$/i) {
	    $insult =~ s/^\s*You are/$who is/i;
	} else {
	    if ($person ne $who) {
		$insult =~ s/^\s*You are/$person is/i;
	    }
	}
	
	if ($insult =~ /\S/) { 
	    if ($param{'babel'} and ($language ne "english")) {
		my $whom = $who;  # building a closure, need lexical
		my $callback = $msgType eq 'public' ? 
		    sub{say("$_[0]")} : sub{msg($whom, $_[0])};
		&babel::forking_babelfish("to", $language, $insult, $callback);
		return 'NOREPLY';
	    }
	} else {
	    $insult = "No luck, $who";
	}

	if ($msgType eq 'public') {
	    &say($insult);
	} else {
	    &msg($who, $insult);
	}
	return "NOREPLY";
    }

    if ($param{'weather'} and ($message =~ /^\s*weather\s+(?:for\s+)?(.*?)\s*\?*\s*$/)) {
	my $code = $1;
	my $weath ;
	if ($code =~ /^[a-zA-Z][a-zA-Z0-9]{3,4}$/) {
	    $weath = &Weather::NOAA::get($code);
	} else {
	    $weath = "Try a 4-letter station code (see http://weather.noaa.gov/weather/curcond.html for locations and codes)";
	}
#	if ($msgType eq 'public') {
#	    &say("$who: $weath");
#	} else {
	    &msg($who, $weath);
#	}
	return 'NOREPLY';
    }

    if (defined $param{'metar'}) {
	my $metar = &metar::get($message);
	if ($metar) {
#	    if ($msgType eq 'public') {
#		&say("$who: $metar");
#	    } else {
		&msg($who, $metar);
#	    }
	    return 'NOREPLY';
	}
    }

    if (defined $param{'uaflight'}) {
	if ($message =~ /usair\s+flight\s+(\d+)/i) {
	    my $res = &UAFlight::get_ua_flight_status($1);
	    if ($res) {
		if ($msgType eq 'public') {
		    &say("$who: $res");
		} else {
		    &msg($who, $res);
		}
		return 'NOREPLY';
	    }
	}
    }

# from Simon: google searching
# modified to fork and generally search by oznoid

    if(defined($param{'wwwsearch'}) and 
       $message =~  /^\s*(?:search\s+)?($W3Search::regex)\s+for\s+['"]?(.*?)['"]?\s*\?*\s*$/i ) {
	 my $callback = $msgType eq 'public' ? 
            sub{say("$who: $_[0]")} : sub{msg($who, $_[0])};
         &W3Search::forking_W3Search($1,$2,$param{'wwwsearch'}, $callback);
       return "NOREPLY";
    }

    # Adam Spiers nickometer
    if ($message =~ /^\s*(?:lame|nick)-?o-?meter(?: for)? (\S+)/i) {
	my $term = $1;
	if (lc($term) eq 'me') {
	    $term = $who;
	}

	$term =~ s/\?+\s*//;

	my $percentage = &nickometer($term);

	if ($percentage =~ /NaN/) {
	    $percentage = "off the scale";
	} else {
	    $percentage = sprintf("%0.4f", $percentage);
	    $percentage =~ s/\.?0+$//;
	    $percentage .= '%';
	}
	
	if ($msgType eq 'public') {
	    &say("'$term' is $percentage lame, $who");
	} else {
	    &msg($who, "the 'lame nick-o-meter' reading for $term is $percentage, $who");
	}

	return 'NOREPLY';
    }

    if ($message =~ /^foldoc(?: for)?\s+(.*)/i) {
	my ($terms) = $1;
	$terms =~ s/\?\W*$//;
	
	my $key= $terms;
	$key =~ s/\s+$//;
	$key =~ s/^\s+//;
	$key =~ s/\W+/+/g;

	my $reply = "$terms may be sought in foldoc at http://wombat.doc.ic.ac.uk/foldoc/foldoc.cgi?query=$key";

	if ($msgType eq 'public') {
	    &say($reply);
	} else {
	    &msg($who, $reply);
	}
	return 'NOREPLY';
    }

    if ($message =~ /^(?:quote|stock price)(?: of| for)? ([A-Z]{1,6})\?*$/) {
	my $reply = "stock quotes for $1 may be sought at http://quote.yahoo.com/q?s=$1\&d=v1";

	if ($msgType eq 'public') {
	    &say($reply);
	} else {
	    &msg($who, $reply);
	}
	return 'NOREPLY';
    }


    if ($message =~ /^rot13\s+(.*)/i) {
	# rot13 it
	my $reply = $1;
	$reply =~ y/A-Za-z/N-ZA-Mn-za-m/;
	if ($msgType eq 'public') {
	    &say($reply);
	} else {
	    &msg($who, $reply);
	}
	return 'NOREPLY';
    }


    if ($addressed)
    {
	my $callback = sub{say("$_[0]")};
	&monty::forking_monty($message, $callback);
    }

    return '';	# do nothing and let the other routines have a go
}

@howAreYa = ("just great", "peachy", "mas o menos", "exhausted",
	 "you know how it is", "eh, ok", "pretty good. how about you");
1;
