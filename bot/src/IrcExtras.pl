
# infobot :: Kevin Lenzo & Patrick Cole   (c) 1997

use Socket;

$| = 1;

$SIG{'INT'}  = 'killed'; 
$SIG{'KILL'} = 'killed';
$SIG{'TERM'} = 'killed';

$VER_MAJ = 0;
$VER_MIN = 44;
$VER_MOD = "2";


$version = "infobot $VER_MAJ\.$VER_MIN\.$VER_MOD [oznoid]";
$updateCount = 0;
$questionCount = 0;
$autorecon = 0;

$label = "(?:[a-zA-Z\d](?:(?:[a-zA-Z\d\-]+)?[a-zA-Z\d])?)";
$dmatch = "(?:(?:$label\.?)*$label)";
$ipmatch = "\d+\.\d+\.\d+\.\d";
$ischan = "[\#\&].*?";
$isnick = "[a-zA-Z]{1}[a-zA-Z0-9\_\-]+";

sub TimerAlarm {
    &status("$TimerWho's timer ended. sending wakeup");
    &say("$TimerWho: this is your wake up call, foobar.");
}

sub killed {
    my $quitMsg = $param{'quitMsg'} || "regrouping";
    &quit($quitMsg);
    &closeDBM("is", "are");
    exit(1);
}

sub joinChan {
    foreach (@_) {
	&status("joined $_");
	rawout("JOIN $_");
    }
}

sub invite {
    my($who, $chan) = @_;
    rawout("INVITE $who $chan");
}

sub notice {
    my($who, $msg) = @_;
    foreach (split(/\n/, $msg)) {
	rawout("NOTICE $who :$_");
    }
}

sub say {
    my $msg=$_[0];
    &status("</$talkchannel> $msg");
    rawout("PRIVMSG $talkchannel :$msg");
}

sub saychan {
    my $chan=$_[0];
    my $msg=$_[1];
    &status("</$chan> $msg");
    rawout("PRIVMSG $chan :$msg");
}

sub msg {
    my ($nick, $msg) = @_;
    &status(">$nick< $msg");
    rawout("PRIVMSG $nick :$msg");
}

sub quit {
    my $quitmsg = $_[0];
    rawout("QUIT :$quitmsg");
    &status("QUIT $param{nick} has quit IRC ($quitmsg)");
    close(SOCK);
}

sub nick {
    $nick = $_[0];
    rawout("NICK ".$nick);
}

sub part {
    foreach (@_) {
	status("left $_");
	rawout("PART $_");
	delete $channels{$_};
    }
}

sub mode {
    my ($chan, @modes) = @_;
    my $modes = join(" ", @modes);
    rawout("MODE $chan $modes");
}

sub op {
    my ($chan, $arg) = @_;
    $arg =~ s/^\s+//;
    $arg =~ s/\s+$//;
    $arg =~ s/\s+/ /;
    my @parts = split(/\s+/, $arg); 
    my $os = "o" x scalar(@parts);
    mode($chan, "+$os $arg");
}

sub deop {
    my ($chan, $arg) = @_;
    $arg =~ s/^\s+//;
    $arg =~ s/\s+$//;
    $arg =~ s/\s+/ /;
    my @parts = split(/\s+/, $arg); 
    my $os = "o" x scalar(@parts);
    &mode($chan, "-$os $arg");
}

sub timer {
    ($t, $timerStuff) = @_;
    # alarm($t);
}

$SIG{"ALRM"} = \&doTimer;

sub doTimer {
    rawout($timerStuff);
}

sub channel {
    if (scalar(@_) > 0) {
	$talkchannel = $_[0];
    }
    $talkchannel;
}

sub rawout {
    $buf = $_[0];
    $buf =~ s/\n//gi;
    select(SOCK); $| = 1;
    print SOCK "$buf\n";
    select(STDOUT);
}

1;
