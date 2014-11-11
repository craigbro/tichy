
# infobot :: Kevin Lenzo & Patrick Cole   (c) 1997

$| = 1;

$SIG{'INT'}  = 'killed'; 
$SIG{'KILL'} = 'killed';
$SIG{'TERM'} = 'killed';

$VER_MAJ = 0;
$VER_MIN = 38;
$VER_MOD = "0b";

$version = "infobot $VER_MAJ\.$VER_MIN\.$VER_MOD [lenzo + cole]";
$updateCount = 0;
$questionCount = 0;
$autorecon = 0;

$label = "(?:[a-zA-Z\d](?:(?:[a-zA-Z\d\-]+)?[a-zA-Z\d])?)";
$dmatch = "(?:(?:$label\.?)*$label)";
$ipmatch = "\d+\.\d+\.\d+\.\d";
$ischan = "[\#\&].*?";
$isnick = "[a-zA-Z]{1}[a-zA-Z0-9\_\-]+";
$SL = c('>', 'bold black').'>'.c('>', 'bold');

sub TimerAlarm {
	&status("$TimerWho's timer ended. sending wakeup");
	say("$TimerWho: this is your wake up call, foobar.");
	say("$TimerWho: And again, fucknut.  WAKE UP!");
}

sub killed {
        my $quitMsg = $param{'quitMsg'} || "regrouping";
	&quit($quitMsg);
	&closeDBM("is", "are");
	exit(1);
}

sub join {
  return "no join yet on zephyr.";
	foreach (@_) {
		&status("joined $_");
		# rawout("JOIN $_");
 	}
}

sub invite {
  return "no invite on zephyr.";
	my($who, $chan) = @_;
	# rawout("INVITE $who $chan");
}

sub notice {
	my($who, $msg) = @_;
	foreach (split(/\n/, $msg)) {
		# rawout("NOTICE $who :$_");
	}
}

sub say1 {
  return "say is unimplemented\n";

	my $msg=$_[0];
	if ($param{ansi_control}) {
		print c('<','red').c($ident, 'bold red').c('>','red')." $msg\n";
	} else {
		print "<$b$ident$ob> $msg\n";
	}
	# rawout("PRIVMSG $talkchannel :$msg");
}

sub msg {
  my ($nick, $msg) = @_;

  print "msg *** " . substr($timestr,11,8) . " *** " . $signature . " (";
  print $sender . "@" . $fromhost . "): ";
  if ($instance ne "PERSONAL") {
    print $instance;
  } 
  print "\n";
  print $body . "\n";

  $msg =~ s/\s+/ /g;
  $msg =~ s/\s*$/\n/;

  if (!$msg) {
    print "empty message: $msg\n";
  } else {
    
#    if ($instance !~ /$contained/) {
#      return '' unless (($instance eq "PERSONAL") || ($instance eq "zurl"));
#    }
    
    print "-> $msg\n";

    # this is a total hack.
    if ($pid = fork) {		# parent
      sleep 1;
      kill 9, $pid;
    } else {			# child
	if ($tell_obj) { 
	    open ZWRITE, "| zwrite -d $nick -s zurl";
	} else {
	    open ZWRITE, "| zwrite -d $fullsender -s zurl";
	}

      $msg =~ s/(.{60,}?) /$1\n/g;
      print ZWRITE $msg;
      close ZWRITE;
      exit(0);
    }
  }

  return '';
}

sub say {
  my $msg = $_[0];

  print "say *** " . substr($timestr,11,8) . " *** " . $signature . " (";
  print $sender . "@" . $fromhost . "): ";
  if ($instance ne "PERSONAL") {
    print $instance;
  } 
  print "\n";
  print $body . "\n";

  $msg =~ s/\s+/ /g;
  $msg =~ s/\s*$/\n/;

  if (!$addressed) {
    print "not addressed\n";
    return;
  }
  if (!$msg) {
    print "empty message: $msg\n";
  } else {
    
#    if ($instance !~ /$contained/) {
#      return '' unless (($instance eq "PERSONAL") || ($instance eq "zurl"));
#    }
    
    print "-> $msg\n";

    # this is a total hack.
    if ($pid = fork) {		# parent
      sleep 1;
      kill 9, $pid;
    } else {			# child
#      if ($instance !~ /infobot/) {
	if ($instance eq "zurl") {
	  open ZWRITE, "| zwrite -d $fullsender -s zurl";
#	open ZWRITE, "| zwrite -s zurl $fullsender";
      } else {
	open ZWRITE, "| zwrite -d -i $instance -s zurl";
#	open ZWRITE, "| zwrite -s zurl -c infobot -i infobot";
      }
      $msg =~ s/(.{60,}?) /$1\n/g;
      print ZWRITE $msg;
      close ZWRITE;
      exit(0);
    }
  }

  return '';
}

sub quit {
	my $quitmsg = $_[0];
	# rawout("QUIT :$quitmsg");
	if ($param{ansi_control}) {
		print "$SL $b$param{nick}$ob has quit IRC ($b$quitmsg$ob)\n";
	} else {
		print ">>> $b$param{nick}$ob has quit IRC ($b$quitmsg$ob)\n";
	}
	close(SOCK);
}

sub nick {
	$nick = $_[0];
	# rawout("NICK ".$nick);
}

sub part {
  return "no part on zephyr\n";

	foreach (@_) {
		status("left $_");
		# rawout("PART $_");
	}
}

sub mode {
  return "no mode on zephyr\n";
	my ($chan, @modes) = @_;
	my $modes = join(" ", @modes);
	# rawout("MODE $chan $modes");
}

sub op {
  return "no op on zephyr\n";
	my ($chan, $arg) = @_;
	$arg =~ s/^\s+//;
	$arg =~ s/\s+$//;
	$arg =~ s/\s+/ /;
	my $os = "o" x scalar(split(/\s+/, $arg));
	mode($chan, "+$os $arg");
}

sub deop {
  return "no deop on zephyr\n";
	my ($chan, $arg) = @_;
	$arg =~ s/^\s+//;
	$arg =~ s/\s+$//;
	$arg =~ s/\s+/ /;
	my $os = "o" x scalar(split(/\s+/, $arg));
	&mode($chan, "-$os $arg");
}

sub timer {
	($t, $timerStuff) = @_;
	# alarm($t);
}

$SIG{"ALRM"} = \&doTimer;

sub doTimer {
	# rawout($timerStuff);
}

sub channel {
  return "no channel on zephyr yet\n";
	if (scalar(@_) > 0) {
		$talkchannel = $_[0];
	}
	$talkchannel;
}

sub rawout {
  print "rawout: $_[0]\n";
  return "";

	$buf = $_[0];
	$buf =~ s/\n//gi;
	select(SOCK); $| = 1;
	print SOCK "$buf\n";
	select(STDOUT);
}

1;
