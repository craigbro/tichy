# This program is copyright Jonathan Feinberg 1999.

# This program is distributed under the same terms as infobot.

# Jonathan Feinberg   
# jdf@pobox.com
# http://pobox.com/~jdf/

# Version 1.0
# First public release.

package travlang;
use strict;

my $no_travlang;

BEGIN {
    eval "use URI::Escape";    # utility functions for encoding the 
    if ($@) { $no_travlang++};    # travlangfish request
    eval "use LWP::UserAgent";
    if ($@) { $no_travlang++};
}

BEGIN {
  # Translate some feasible abbreviations into the ones travlangfish
  # expects.
    use vars qw!%lang_code $lang_regex!;
    %lang_code = (
		no => 'Norwegian',
		da => 'Danish',
		sw => 'Swedish',
		fi => 'Finnish',
		fr => 'Frisian',
		cz => 'Czech',
		es => 'Esperanto',
		la => 'Latin'
	       );
  
  # Here's how we recognize the language you're asking for.  It looks
  # like RTSL saves you a few keystrokes in #perl, huh?
  $lang_regex = join '|', keys %lang_code;
}


sub forking_travlang {
    return '' if $no_travlang;
   my ($direction, $lang, $phrase, $callback) = @_;
   $SIG{CHLD} = 'IGNORE';
   my $pid = eval { fork() };   # catch non-forking OSes and other errors
   return if $pid;              # parent does nothing
   $callback->(travlang($direction, $lang, $phrase));
   exit 0 if defined $pid;      # child exits, non-forking OS returns
}

sub travlang {
    return '' if $no_travlang;
  my ($direction, $lang, $phrase) = @_;
  
    my $req;
  $lang = $lang_code{$lang};

  my $ua = new LWP::UserAgent;
  $ua->timeout(4);

  my $urltext = uri_escape($phrase);
  my $tolang = "http://dictionaries.travlang.com/English$lang/dict.cgi?query=$urltext&max=1";
  my $toenglish = "http://dictionaries.travlang.com/${lang}English/dict.cgi?query=$urltext&max=1";

  if ($direction eq 'to') {
      $req = HTTP::Request->new('GET', $tolang);
    return translate($req, $ua);
  }
  elsif ($direction eq 'from') {
      $req = HTTP::Request->new('GET', $toenglish);
    return translate($req, $ua);
  }

    return "What??";
}


sub translate {
    return '' if $no_travlang;
  my ($req, $ua) = @_;
  
  my $res = $ua->request($req);

  if ($res->is_success) {
      my $html = $res->content;
      # This method subject to change with the whims of Altavista's design
      # staff.
      my ($translated) = 
	  ($html =~ m{<pre>[^.]+.\s+([^0-9<]*)}sx);
      $translated =~ s/\n/ /g;
      $translated =~ s/\s*$//;
     $translated =~ s/&aacute;/á/g;
     $translated =~ s/&oacute;/ó/g;
     $translated =~ s/&uuml;/ü/g;
     $translated =~ s/&ouml;/ö/g;
     $translated =~ s/&otilde;/ô/g;
     $translated =~ s/&eacute;/é/g;
     $translated =~ s/&iacute;/í/g;

      return $translated;
  } else {
      return ":("; # failure 
  }
}

"Hello.  I'm a true value.";
