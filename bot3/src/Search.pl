# infobot copyright kevin lenzo 1997-1998

sub search {
    my $pattern = $_[0];

    if (0 & $addressed && ($msgType ne 'dcc_chat')) {
	&msg($who, "this search requires dcc chat.  /dcc chat $nick   and then try again.");
	return 'NOREPLY';
    } else {
	if ($pattern =~ s/^\d+ //) {
	    $bail_thresh = $&; 
	} else {
	    $bail_thresh = 10;
	}

	$pattern =~ s/\?+\s*$//;
	return "" if ($pattern =~ /^\s*$/);
	my $MINL = 3;

	return "that pattern's too short.  try something with at least $MINL characters." if (length($pattern) < $MINL);

	&msg($who,"Looking for $pattern:");

	my (@response, $bail, $perfect);

	my (@myIsKeys) = getDBMKeys("is");
	my (@myAreKeys) = getDBMKeys("are");

	foreach (@myIsKeys) {
	    if ($_ =~ /^$pattern$/) {
		$r = &get("is", $_);
		$perfect = "$_ is $r";
		last if ($in =~ /^\s*scan/i);
		next;
	    }
	    if ($_ =~ /$pattern/) {
		$r = &get("is", $_);
		push(@response, "$_ is $r") 
		    unless ++$bail > $bail_thresh;
		last if ($in =~ /\s*scan/i);
	    }
	}
	if (($in =~ /search/) || (!$perfect)) {
	    foreach (@myAreKeys) {
		if ($_ =~ /^$pattern$/) {
		    $perfect .= "; " if $perfect;
		    $r = &get("are", $_);
		    $perfect .= "$_ are $r";
		    last if ($in =~ /^\s*scan/i);
		    next;
		}
		if ($_ =~ /$pattern/) {
		    $r = &get("are", $_);
		    push(@response, "$_ are $r")
			unless ++$bail > $bail_thresh;
		    last if ($in =~ /^\s*scan/i);
		}
	    }
	} 

	if ((@response == 0) && (!$perfect)) {
	    return "nothing";
	} else {
	    foreach (@response) {
		&msg($who, $_);
	    }
	    if ($bail > $bail_thresh) {
		&msg($who,"	 ...showing first $bail_thresh hash table hits.");
	    }

	    return "$perfect" if ($perfect);

	    if (($in =~ /\s*scan/i) && ($bail > 0)) {
		return "	 ...scan hit; terminated";
	    }

	    undef(@response);
	    return " ";
	}
	return " ";
    }
}

1;
