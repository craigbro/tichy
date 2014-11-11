#!/usr/local/bin/perl

while (<>) {
  if (/I-PC$/ && !inside_pp) {
    s/I-PC$/0/;
  }
  if (/^(.*)-(.*)\t(.*)\/(.*)$/) {
    $token = $1;
    $tag = $2;
    $chunk = $4;
    if ($chunk =~ /^(.*)-(.*)$/) {
      $flag = $1;
      $chunk = $2;
    }
    else {
      undef $flag;
      undef $chunk;
    }
    if ($flag eq 'B' || $chunk ne $old_chunk) {
      if (defined $old_chunk) {
	if ($old_chunk eq 'PC') {
	  $inside_pp = 1;
	} 
	else {
	  print "</$old_chunk>\n";
	  if ($inside_pp) {
	    print "</PC>\n";
	    undef $inside_pp;
	  }
	}
      }
      print "<$chunk>\n" if (defined $chunk);
      $old_chunk = $chunk;
    }
    print "$token\t$tag\n";
    if (defined $inside_pp && !defined $chunk) {
      print "</PC>\n";
      undef $inside_pp;
    }
  } 
  else {
    if (defined $old_chunk) {
      print "</$old_chunk>\n";
      if ($inside_pp) {
	print "</PC>\n";
	undef $inside_pp;
      }
      undef $old_chunk;
    }
    print;
  }
}
