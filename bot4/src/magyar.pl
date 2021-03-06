# This program is copyright Jonathan Feinberg 1999.

# This program is distributed under the same terms as infobot.

# Jonathan Feinberg   
# jdf@pobox.com
# http://pobox.com/~jdf/

# Version 1.0
# First public release.

# Hacked on by JLB February 1st, 1900

package monty;
use strict;

my $no_monty;

BEGIN {
    eval "use URI::Escape";    # utility functions for encoding the 
    if ($@) { $no_monty++};    # montyfish request
    eval "use LWP::UserAgent";
    if ($@) { $no_monty++};
}

sub forking_monty {
    return '' if $no_monty;
   my ($message, $callback) = @_;
   $SIG{CHLD} = 'IGNORE';
   my $pid = eval { fork() };   # catch non-forking OSes and other errors
   return if $pid;              # parent does nothing
   $callback->(monty($message));
   exit 0 if defined $pid;      # child exits, non-forking OS returns
}

sub monty {
    return '' if $no_monty;
  my ($direction, $phrase) = @_;

  my $ua = new LWP::UserAgent;
  $ua->timeout(6);

  my $req = HTTP::Request->new('POST', 'http://www.sztaki.hu/cgi-bin/szotar/dict_search');
  $req->content_type('application/x-www-form-urlencoded');
  
  return translate($phrase, $direction, $req, $ua);
}


sub translate {
    return '' if $no_monty;
  my ($phrase, $direction, $req, $ua) = @_;
  
  my $urltext = uri_escape($phrase);

  if ($direction eq 'to') {
    $req->content("L=ENG:HUN:EngHunDict&M=0&W=$phrase&O=ENG&F=1&A=1&C=1");
  } else {
    $req->content("L=HUN:ENG:EngHunDict&M=0&W=$phrase&O=ENG&F=1&A=1&C=1");
  }

  my $res = $ua->request($req);

  if ($res->is_success) {
      my $html = $res->content;

      if ($direction eq 'to') {
      my ($translated) = 
	  ($html =~ m{<BR><I>$phrase</I>[^>]+>([^<]*)}sx);
     $translated =~ s/\n/ /g;
     $translated =~ s/\s*$//;
     $translated =~ s/&aacute;/�/g;
     $translated =~ s/&oacute;/�/g;
     $translated =~ s/&uuml;/�/g;
     $translated =~ s/&ouml;/�/g;
     $translated =~ s/&otilde;/�/g;
     $translated =~ s/&eacute;/�/g;
     $translated =~ s/&iacute;/�/g;
#     printf $html;
#     printf "\n";
      return $translated;
  } else {
      my ($translated) = 
	  ($html =~ m{<BR><I>[^<]+</I>[^>]+>([^<]*)}sx);
     $translated =~ s/\n/ /g;
     $translated =~ s/\s*$//;
     $translated =~ s/&aacute;/�/g;
     $translated =~ s/&oacute;/�/g;
     $translated =~ s/&uuml;/�/g;
     $translated =~ s/&ouml;/�/g;
     $translated =~ s/&otilde;/�/g;
     $translated =~ s/&eacute;/�/g;
     $translated =~ s/&iacute;/�/g;
#     printf $translated;
#     printf "\n";
      return $translated;
  }

  } else {
      return ":("; # failure 
  }
}

"Hello.  I'm a true value.";
