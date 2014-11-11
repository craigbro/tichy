#!/usr/local/bin/perl

# usage:
#   tzc-zwgc [-allpersonal] [-nopersonal] [regexp]
# only zgrams with instance matching regexp will be printed

# to use non-message class
#  ((tzcfodder . subscribe) ("SOMECLASS" "*" "*"))

if (0) {
  $allpersonal = 0;
  $nopersonal = 0;
  
  while (($arg = shift) && ($arg =~ /^-/)) {
    if ($arg eq "-allpersonal") {
      $allpersonal = 1;
    } elsif ($arg eq "-nopersonal") {
      $nopersonal = 1;
    } else {
      print STDERR "Unknown argument: $arg\n";
      exit(-1);
    }
    
    if ($arg = shift) {
      print STDERR "Extraneous argument: $arg\n";
      exit(-1);
    }
  }
  $regexp = $arg;
}
$allpersonal = 1;
$regexp = "";
$contained = "^infobot";

sub Zephyr {
  $| = 1;
  
 restart: while (1) {
    open (F, "tzc -o |") || die "can't run tzc\n";

    select F;
    $/ = "\000";
    select STDOUT;

    while (<F>) {
      # cut off everything up to & including the first ^A.

      $i = index($_,"\001");
      if ($i >= 0) {
	$_ = substr($_,$i+1);
      }

      # get tzcspew tag (a symbol, usually "message")
      if (/\(tzcspew \. ([^\)]*)\)/) {
	$spew = $1;
      } else {
	next;
      }
      # on cutoff, try to restart
      if ($spew eq 'cutoff') {
	print "CUTOFF DETECTED.  RESTARTING...\n";
	next restart;
      } elsif ($spew eq 'start') {
	# ignore startup msg
	next;
      }
      
      # ignore pings 
      if (/\(opcode . PING\)/) {
	next;
      }
      # class (this is a symbol, although it probably shouldn't be)
      if (/\(class \. ([^\)]*)\)/) {
	$class = $1;
      } else {
	print "BAD CLASS: $_\n";
      }
      # sender
      if (/\(sender \. "((\\.|[^\"\\])*)"\)/) {
	$sender = &unquote($1);
	# truncate, e.g., "dk3q@ANDREW.CMU.EDU", to "dk3q@ANDREW".
	$fullsender = $sender;
	if ($sender =~ /^(.*@[^\.]*)\./) {
	  $sender = $1;
	}
      } else {
	print "BOGUS SENDER: $_";
      }
      # recipient (usually empty string or your kerberos principal)
      if (/\(recipient \. \"((\\.|[^\"\\])*)\"\)/) {
	$recipient = &unquote($1);
      } else {
	print "BOGUS RECIPIENT: $_";
      }
      # timestamp assigned at sending host
      if (/\(time \. \"((\\.|[^\"\\])*)\"\)/) {
	$timestr = &unquote($1);
	$month = substr($timestr,4,3);
	$hour = substr($timestr,11,2);
	$day = substr($timestr,0,3);
      } else {
	print "BOGUS TIME: $_";
      }
      # host which sent the zgram
      if (/\(fromhost \. \"((\\.|[^\"\\])*)\"\)/) {
	$fromhost = &unquote($1);
      } else {
	print "BOGUS FROMHOST: $_";
      }
      # message (signature & body)
      if (/\(message[ .\(]*\"((\\.|[^\"\\])*)\" \"((\\.|[^\"\\])*)/) {
	$signature = &unquote($1);
	$body = &unquote($3);
	$signature =~ s/\n//;
      } else {
	# just skip messages with <2 parts
	# (might be better to print with empty body
	next;
      }
      # instance
      if (/\(instance \. \"((\\.|[^\"\\])*)\"\)/) {
	$instance = &unquote($1);
      } else {
	print "BOGUS INSTANCE: $_";
      }
      
      # if $allpersonal <> 0 then accept all personal zgrams
      if (! ($allpersonal && $recipient ne "")) {
	# reject personal zgrams if $nopersonal is nonzero
	next if ($nopersonal && $recipient ne "");
	
	# reject if $regexp is nonempty, it's not a personal zgram, and
	# instance doesn't match $regexp
	next if ($regexp ne "" && $instance !~ /$regexp/);
	
	if (defined $ENV{'TZC_ZWGC_FILTER'} && -r $ENV{'TZC_ZWGC_FILTER'}) {
	  do $ENV{'TZC_ZWGC_FILTER'};
	}
	# other possible customizations:
	#   next if ($instance =~ /^zippy/);     # ignore zippy* instances
	#   next if ($sender =~ /^gusciora$/);   # ignore goofballs
      }
      
      # add terminating newline if necessary
      if (substr($body,length($body)-1) ne "\n") {
	$body = $body . "\n";
      }  

      next if $instance =~ /^graffiti/i;
      next if ($instance eq "PERSONAL");
      next if $signature eq "zurl";

      $body =~ s/\s+/ /g;

      $who = lc($sender);
      $nick = "zurl";
      $param{nick} = $nick;

      $body =~ s/^\s*infobot/zurl/i;
      &ZephyrMsgHook($sender, $fromhost, $recipient, $instance, $timestr, $body, $signature);
    }
    close(F) || die "error in tzc\n";
  }
  exit(0);
}

############################################
sub unquote {
	local($s) = @_;
        $s =~ s/\\(.)/$1/g;
        return $s;
}      

