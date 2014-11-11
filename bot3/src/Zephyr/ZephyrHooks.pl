
# infobot :: Kevin Lenzo  (c) 1997

# Tidied up ?

sub ZephyrActionHook
{
  my ($nick, $channel, $message) = @_;
  &channel($channel);
  &process(0, $nick, 'public action', $message);
}

sub ZephyrMsgHook
{
  my ($sender, $fromhost, $recipient, $instance, $timestr, $body, $signature) = @_;

  $body =~ s/\s+/ /g;
  $body =~ s/\s+$//;
  $body =~ s/^\s+//;

  my $xtype = "public";
  if (($recipient ne "") && ($recipient ne "*")) {
      $xtype = "private";
  }

  my ($adr, $type, $channel, $who, $message) = (0, $xtype, $instance, $sender, $body);

  #	return if ($ignoreList =~ /$who/);
  
  if ($MLF{$who} == 1) {	# This person is doing a mlf !!!
    if ($message =~ /^<end>$/) {
      ${$who.'ft'} =~ s/\n+$//;
    if ($MLF{$who.'verb'} eq "is") {
      &set("is", $MLF{$who.'word'}, "MLF:".${$who.'ft'});
    $is{"theCount"}++;
  } elsif ($MLF{$who.'verb'} eq "are") {
    &set("are", $MLF{$who.'word'}, "MLF:".${$who.'ft'});
  $are{"theCount"}++;
}
  undef ${$who.'ft'};
  $MLF{$who} = 0;
			&status("MLF Added: $MLF{$who.'word'}");
		} else {
			$message =~ s/\n//;
			&status("ack: $message");
			${$who.'ft'} .= $message;
			${$who.'ft'} .= "\r";
		}
		return;
	}

	if ($type =~ /public/i)	{
		if ($adr == 1) {
			$addressed_count++;
		}
		&channel($channel);
		&process($adr, $who, $type, $message);
		$lastAddressedBy = $who if ($adr);
	}

	if ($type =~ /private/i) {
		if (($params{'mode'} eq 'IRC') && ($who eq $prevwho)) {
			$delay = time-$prevtime."\n";
			$prevcount++;
			if ($delay < 1) {
				if (!grep /^$who$/i, @specialPeople) {
					&msg($who, "You will be ignored -- flood detected.");
					#$ignore{$who}++;
					&track("ignoring ".$who);
					# $ignoreList .= " ".$t;
					return;
				}
			}
			return if (($message eq $prevmsg) && ($delay < 10));
		} else {
			$prevcount = 0;
			$firsttime = time;
		}
		$prevtime = time unless ($message eq $prevmsg);
		$prevmsg = $message;
		$prevwho = $who;
		&process($adr, $who, $type, $message);
	}
	return;
}

sub hook_dcc_request
{
	my($type, $text) = @_;
	if ($type =~ /chat/i) {
	&status("received dcc chat request from $who  :  $text");
	my($locWho) = $who;
	$locWho =~ tr/A-Z/a-z/;
	$locWho =~ s/\W//;
	&docommand("dcc chat ".$who);
	&msg('='.$who, "Hello, ".$who);
	}
}

sub hook_dcc_chat
{
	my($locWho, $message)=@_;
	$msgType = "dcc_chat";
	my($saveWho) = $who;

	return if ($message =~ /enter your password/i);
	return if ($who =~ /poundmac/i);
	return if ($locWho =~ /poundmac/i);

	$who = "=".$who;
	&process($msgType, $message);
	$who = $saveWho;
}

1;
