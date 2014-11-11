# infobot :: Kevin Lenzo  (c) 1997

$DBformat = "lllll"; 
$DBprefix = 'HASH_';
if (!$filesep) {
    $filesep = '/';
}

sub openDBM {
    my %newDBMS = @_;
    my $created = 0;
    my $failed = 0;

    # wix++ {
#     tie %seen, 'DB_File', "tree", O_RDWR|O_CREAT, 0644, $DB_BTREE;
#     tie %maillist, 'DB_File', "users", O_RDWR|O_CREAT, 0644, $DB_BTREE;
    # }

    foreach $d (keys %newDBMS) {
	next if $d =~ /^\s*$/;
	if (defined($DBMS{$d})) {
	    &status("$newDBMS{$d} replaces $DBMS{$d}")
		unless $DBMS{$d} eq $newDBMS{$d};
	}

	if (dbmopen(%{"$DBprefix$d"}, $newDBMS{$d}, undef)) {
	    &status("opened $d -> $newDBMS{$d}");
	    $DBMS{$d} = $newDBMS{$d};
	} else {
	    if (dbmopen(%{"$DBprefix$d"}, $newDBMS{$d}, 0644)) {
		&status("created new db\t$d -> $newDBMS{$d}");
		$DBMS{$d} = $newDBMS{$d};
		$created++;
		my $c = 0;
		my $initfile = "$param{miscdir}/infobot-$d.txt";
		my $dbname = $DBprefix.$d;
		&insertFile($initfile, $dbname);

	    } else {
		&status("failed to open $d -> $newDBMS{$d}");
		++$failed;
	    }
	}
    }
    return $failed;
}

sub insertFile {
    my ($factfile, $dbname) = @_;

    if (open(IN, $factfile)) {
	my ($good, $total);

	while(<IN>) {
	    chomp;
	    my ($k, $v) = split(/\s*=>\s*/, $_, 2);
	    if ($k and $v) {
		$$dbname{$k} = $v;
		$good++;
	    } 
	    $total++;
	}
	close(IN);
	$dbname =~ s/^HASH_//;
	&status("loaded $factfile into $dbname ($good/$total good items)");
    } else {
	$dbname =~ s/^HASH_//;
	&status("FAILED to load $factfile into $dbname");
    }
}

sub closeDBM {
    untie %seen;
    untie %maillist;
    
   if (@_) {
	foreach $d (@_) {
	    dbmclose(%{"$DBprefix$d"});
	    &status("closed db $d");
	}
    } else {
	&status("No dbs specified; none closed");
    }

}

sub set {
    my ($db, $key, $val) = @_;
    my %dbs = %DBMS;

    if (!$key) {
	($db, $key, $val) = split(/\s+/, $db);
    }

    # this is a hack to keep set param consistant.. overloaded
    if ($db eq 'param') {
	my $was = $param{$key};
	$param{$key} = $val;
	return $was;
    }

    $dbname = "$DBprefix$db";
    my $was = $$dbname{$key};
    $$dbname{$key} = $val;

    #if ($param{'commitDBM'} eq 'ALWAYS') {
    # close and reopen the dbm file on each update.
    # what a pain.  some implemenations commit to
    # disk on every update; some, however, do not.
    # if you don't do this on the ones that do not,
    # you can lose all new updates if the process
    # dies.
    #	&closeDBM($db);
    #	my $trycount = 0;
    #	while ((++$trycount < 10) && &openDBM($db => $dbs{$db})) {
    #		sleep 1;
    #	}
    #} elsif ($param{'commitDBM'} =~ /^\d+/) {
    #	if (!(++$strobe % $param{'commitDBM'})) {
    #		# close and reopen the dbm file every N
    #		# allow a refractory period.  the dbm takes some time
    #		# to close and reopen. this is safer but still
    #		# a rather stupid way to do this.
    #		&closeDBM($db);
    #		my $trycount = 0;
    #		while ((++$trycount < 10) && &openDBM($db => $dbs{$db})) {
    #			sleep 1;
    #		}
    #	}
    #}
    return $was;
}

sub get {
    my ($db, $key) =@_;

    if (!$key) {
	($db, $key) = split(/\s+/, $db);
    }
    $db = "$DBprefix$db";

    return ${$db}{$key};
}

sub whatdbs {
    my @result;
    foreach (keys %DBMS) {
	push(@result, "$_ => $DBMS{$_}");
    }
    return @result;
}

sub showdb {
    my ($db, $regex) = @_;
    my @result;

    if (!$regex) {
	($db, $regex) = split(/\s+/,$db, 2);
    }

    my @whichdbs;

    if (!$db) {
	&status("no db given");
	&status("try showdb <db> <regex>");
	# @whichdbs = (keys %DBMS);
    } else {
	@whichdbs = ($db);
    }

    foreach $db (@whichdbs) {
	my $thedb = "$DBprefix$db";
	if (!defined($DBMS{$db})) {
	    &status("the database $db is not open.");
	    &status("try showdb <db> <regex>");
	    return();
	}
	if (!$regex) {
	    &status("showing all of $db");
	    foreach (keys %{$thedb}) {
		push(@result, "$_ => ${$thedb}{$_}");
	    }	
	} else {
	    &status("searching $db for /$regex/");
	    my $k;
	    foreach $k (keys %{$thedb}) {
		my $v = $$thedb{$k};
		if (($k =~ /$regex/) || ($v =~ /$regex/)) {
		    push(@result, "$k => ${$thedb}{$k}");
		}
	    }
	}
    }
    return @result;
}

sub forget {
    &clear(@_);
    return '';
}

sub clear {
    my ($db, $key) =@_;

    if (!$key) {
	($db, $key) = split(/\s+/, $db);
    }
    my $thedb = "$DBprefix$db";
    my $was = get($db, $key);
    
    print "DELETING $thedb $key \n";
    delete $$thedb{$key};
    print "DELETED\n";

    return '';
}

sub getDBMKeys {
    my $what = $_[0];
    return keys %{"$DBprefix$what"};
}

sub basename {
    my $x = $_[0];
    $x =~ s/.*\///;
    return $x;
}

1;
