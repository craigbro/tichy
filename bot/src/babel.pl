# This program is copyright Jonathan Feinberg 1999.

# This program is distributed under the same terms as infobot.

# Jonathan Feinberg   
# jdf@pobox.com
# http://pobox.com/~jdf/

# Version 1.0
# First public release.

package babel;
use strict;

my $no_babel;

BEGIN {
    eval "use URI::Escape";    # utility functions for encoding the 
    if ($@) { $no_babel++};    # babelfish request
    eval "use LWP::UserAgent";
    if ($@) { $no_babel++};
}

BEGIN {
  # Translate some feasible abbreviations into the ones babelfish
  # expects.
    use vars qw!%lang_code $lang_regex!;
    %lang_code = (
		fr => 'fr',
		sp => 'es',
		po => 'pt',
		pt => 'pt',
		it => 'it',
		ge => 'de',
		de => 'de',
		gr => 'de',
		en => 'en',
		ja => 'ja',
		ko => 'ko',
		ch => 'zh',
		ru => 'ru'
	       );

  # Here's how we recognize the language you're asking for.  It looks
  # like RTSL saves you a few keystrokes in #perl, huh?
  $lang_regex = join '|', keys %lang_code;
}


sub forking_babelfish {
    return '' if $no_babel;
   my ($direction, $lang, $phrase, $callback) = @_;
   $SIG{CHLD} = 'IGNORE';
   my $pid = eval { fork() };   # catch non-forking OSes and other errors
   return if $pid;              # parent does nothing
   $callback->(babelfish($direction, $lang, $phrase));
   exit 0 if defined $pid;      # child exits, non-forking OS returns
}

sub babelfish {
    return '' if $no_babel;
  my ($direction, $lang, $phrase) = @_;
  
  $lang = $lang_code{$lang};

  my $ua = new LWP::UserAgent;
  $ua->timeout(4);

  my $req =  
    HTTP::Request->new('POST',
		       'http://babelfish.altavista.com/babelfish/tr');
  $req->content_type('application/x-www-form-urlencoded');
  
  my $tolang = "en_$lang";
  my $toenglish = "${lang}_en";
printf($tolang.$toenglish);

  if ($direction eq 'to') {
    return translate($phrase, $tolang, $req, $ua);
  }
  elsif ($direction eq 'from') {
    return translate($phrase, $toenglish, $req, $ua);
  }
  elsif ($direction eq 'toandfro') {
    my $intermediate = translate($phrase, $tolang, $req, $ua);
    return translate($intermediate, $toenglish, $req, $ua);
  }

  my $last_english = $phrase;
  my $last_lang;
  my %results = ();
  my $i = 0;
  while ($i++ < 7) {
    last if $results{$phrase}++;
    $last_lang = $phrase = translate($phrase, $tolang, $req, $ua);
    last if $results{$phrase}++;
    $last_english = $phrase = translate($phrase, $toenglish, $req, $ua);
  }
  return $last_english;
}


sub translate {
    return '' if $no_babel;
  my ($phrase, $languagepair, $req, $ua) = @_;
  
  my $urltext = uri_escape($phrase);
  $req->content("tt=urltext&intl=1&trtext=$urltext&lp=$languagepair&doit=done");

  my $res = $ua->request($req);

  if ($res->is_success) {
      my $html = $res->content;

      if (open POUT, ">/tmp/xxx") {
	  print POUT "$html\n";
	  close POUT;
      }
      # printf $html;

      # This method subject to change with the whims of Altavista's design
      # staff.
      my ($translated) = 
	  ($html =~ m{(?:10px\;>|lang=[a-z]+>)([^<]*)
					      }sx);
      $translated =~ s/\n/ /g;
      $translated =~ s/\s*$//;
	
       printf("T Input = ");
       printf $phrase;
       printf "\n";
       printf("T Output = ");
       printf $translated;
       printf "\n";
      return $translated;
  } else {
      return ":("; # failure 
  }
}

babelfish('toandfro', 'ko', 'there goes the neighborhood');


"Hello.  I'm a true value.";
