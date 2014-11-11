# infobot :: Kevin Lenzo  (c) 1997

## 
##  doQuestion --
## 
##	decide if $in is a query, and if so, return its value.
##	otherwise return null. 
##

sub doQuestion {
    local ($msgType, $in) = @_;
    chomp $in;

    $finalQMark = $in =~ s/\?+\s*$//;

    $questionWord = "";		# this is shared for a reason
    $input_message_length = length($in);

    my($locWho) = $who;
    local ($lhs, $res, $num);
    $locWho =~ tr/A-Z/a-z/;
    $locWho =~ s/^=//;

    my ($origIn) = $in;
    $finalQMark += $in =~ s/\?\s*$//;

    # dangerous; common preambles should be stripped before here

    if ($in !~ /^forget /i and $in !~ /^no, /) {
	$result = &getReply($msgType, $in);
	if ($result) {
	    &status("match: $in => $result");
	    return $result;
	}
    }  else {
	return 'NOREPLY' if $infobots{$nuh};
    }

    if (($addressed) && ($in =~ /^\s*help\b/i)) {
	$in =~ s/^\s*help\s*//i;
	$in =~ s/\W+$//;
	&help($in);
	return 'NOREPLY';
    }
    
#    if (IsFlag("s") eq "s") {
	if ($in =~ /^\s*(scan|search)\s*for\s+/i) {
	    &search($`);
	    return 'NOREPLY';
	}
#    }

    if ($param{'allowConv'}) { 
	if ($in =~ /^\s*(asci*|chr) (\d+)\s*$/) {
	    $num = $2;
	    if ($num < 32) {
		$num += 64;
		$res = "^".chr($num);
	    } else {
		$res = chr($2);
	    }
	    if ($num == 0) { $res = "NULL"; } ;
	    return "ascii ".$2." is \'".$res."\'";
	}
	if ($in =~ /^\s*ord (.)\s*$/) {
	    $res = $1;
	    if (ord($res) < 32) {
		$res = chr(ord($res) + 64);
		if ($res eq chr(64)) {
		    $res = 'NULL';
		} else {
		    $res = '^'.$res;
		}
	    }
	    return "\'$res\' is ascii ".ord($1);
	}
    }

    if ($param{'plusplus'}) {
	my $in2 = $in;

	if ($in2 =~ s/^(karma|score)\s+(for\s+)?//) {
	    $in2 = lc($in2);
	    $in2 =~ s/\s+/ /g;
	    if ($in2 eq "me") {
		$in2 = lc($who);
	    }
   	    if (defined($plusplus{$in2}) and $plusplus{$in2}) {
		return "$in2 has karma of $plusplus{$in2}";
	    } else {
		return "$in2 has neutral karma";
	    }
	}
    }


    if (($addressed) && ($in =~ /^statu?s/)) {
	$upString = &timeToString(time()-$startTime);
	$eTime = &get("is", "the qEpochDate");
	return "Since $setup_time, there have been $updateCount modifications and $questionCount questions.  I have been awake for $upString this session, and currently reference $factoidCount factoids. Addressing is in ".lc($param{addressing})." mode.";
	#  Since ".$is{"the qEpochDate"}." there have been about ".$is{"the qCount"}." questions total.";
    }

    # the thing to tell someone about ($tell_obj)
    $tell_obj = "";

    # who to tell
    $target = $who;

    # i'm telling!
    if ($param{'allowTelling'}) {
	# this one catches most of them
	if ($in =~ /^tell\s+(\S+)\s+about\s+(.*)/i) {
	    $target = $1;
	    $tell_obj = $2;

	    if ($target =~ /^us$/i) { # tell us 
		$target = "";
	    } elsif ($tell_obj =~ /^(me|myself)$/i) { 
		$tell_obj = $who;
	    }

	    $in = $tell_obj;

	} elsif ($in =~ /tell\s+(\S+)\s+where\s+(\S+)\s+can\s+(\S+)\s+(.*)/i) {
	    # i'm sure this could all be nicely collapsed
	    $target = $1;
	    $tell_obj = $4;
	    if ($target =~ /^us$/i) {
		$target = "";
	    }
	    $in = $tell_obj;
	} elsif ($in =~ /tell\s+(\S+)\s+(what|where)\s+(.*?)\s+(is|are)[.?!]*$/i) {
	    $target = $1;
	    $qWord = $2;
	    $tell_obj = $3;
	    $verb = $4;
	    if ($target =~ /^us$/i) {
		$target = "";
	    }
	    $in = "$qWord $verb $tell_obj";
	}

	if (($target =~/^\s*[\&\#]/) or ($target =~ /\,/)) {
	    $target = "";
	    $tell_obj = "";
	    return "No, ".$who.", i won\'t";
	}

	if ($target eq $param{'nick'}) {
	    $target = "";
	    return "Isn\'t that a bit silly, ".$who."?";
	}
	$tell_obj =~ s/[\.\?!]+$//;

    }

    # convert to canonical reference form
    $in = &normquery($in);
    $in = &switchPerson($in);


    # where is x at?
    $in =~ s/\s+at\s*(\?*)$/$1/;

    $in = " $in ";

    my $qregex = join '|', @qWord;

    # what's whats => what is; who'?s => who is, etc
    $in =~ s/ ($qregex)\'?s / $1 is /i;
    if ($in =~ s/\s+($qregex)\s+//i) { # check for question word
	$questionWord = lc($1);
    }

    $in =~ s/^\s+//;
    $in =~ s/\s+$//;

    if (($questionWord eq "") && ($finalQMark > 0) && ($addressed > 0)) {
	$questionWord = "where";
    }

    # $lhs (left hand side) becomes the result of the query
    # about $in (otherwise knowable as $rhs, the right hand side)

    $lhs = &getReply($msgType, $in);
    $answer = $lhs;

    return 'NOREPLY' if ($answer eq 'NOREPLY');

    if (($param{'addressing'} eq 'REQUIRE') && !$addressed) {
	return 'NOREPLY';
    }

    &math(); # clean up the argument syntax for this later

    if ($questionWord ne "" or $finalQMark) {
	# if it has not been explicitly marked as a question
	if (($addressed > 0) && ($lhs eq "")) {
	    # and we're addressed and so far the result is null
	    &status("notfound: <$who> $origIn :: $in");
	    my($reply) = "";

	    return 'NOREPLY' if $infobots{$nuh};

	    # generate some random i-don't-know reply.
	    if (0 and ($x = rand()) > 0.8) {
		$reply = "well ";
	    } 

	    $reply .= $dunno[int(rand(@dunno))];

	    if (rand() > 0.5) {
		$reply = $locWho.": ".$reply;
	    } else {
		$reply = $reply.", ".$locWho;
	    }

	    &askFriendlyBots($in);

	    # and set the result
	    $lhs = "";
#$reply;
	}
    } else {
	# the item was found
	if ($lhs ne "") {
	    &status("match: $in => $lhs");
	}
    }

    $lhs;
}

sub timeToString {
	my $upTime = $_[0];
	$upTime = (time()-$startTime);
	my $upDays = int($upTime / (60*60*24));
	my $upString = "";
	if ($upDays > 0) {
		$upString .= $upDays." day";
		$upString .= "s" if ($upDays > 1);
		$upString .=", ";
	}
	$upTime -= $upDays * 60*60*24;
	my $upHours = int($upTime / (60*60));
	if ($upHours > 0) {
		$upString .= $upHours." hour";
		$upString .= "s" if ($upHours > 1);
		$upString .=", ";
	}
	$upTime -= $upHours *60*60;
	my $upMinutes = int($upTime / 60);
	if ($upMinutes > 0) {
		$upString .= $upMinutes." minute";
		$upString .= "s" if ($upMinutes > 1);
		$upString .=", ";
	}
	$upTime -= $upMinutes * 60;
	my $upSeconds = $upTime;
	$upString .= $upSeconds." second";
	$upString .= "s" if ($upSeconds != 1);
	$upString;
}

1;
