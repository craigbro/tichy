#!/usr/bin/perl

package Weather;

# kevin lenzo (C) 1999 -- get the weather forcast NOAA.
# feel free to use, copy, cut up, and modify, but if
# you do something cool with it, let me know.

my $no_weather;
my $cache_time = 60 * 40 ; # 40 minute cache time
my $default = 'KAGC';

BEGIN {
    $no_weather = 0;
    eval "use LWP::Simple";
    $no_weather++ if ($@);
}

sub Weather::NOAA::get {
    my ($station) = shift;
    $station = uc($station);
    my $result;

    if ($no_weather) {
	return 0;
    } else {

	if (exists $cache{$station}) {
	    my ($time, $response) = split $; , $cache{$station};
	    if ((time() - $time) < $cache_time) {
		return $response;
	    }
	}

	my $content = LWP::Simple::get("http://tgsv7.nws.noaa.gov/weather/current/$station.html");

	if ($content =~  /ERROR/i) {
	    return "I can't find that station code (see http://weather.noaa.gov/weather/curcond.html for locations codes)";
	}

	$content =~ s|.*?current weather conditions.*?</TR>||is;

	$content =~ s|.*?<TR>(?:\s*<[^>]+>)*\s*([^<]+)\s<.*?</TR>||is;
	my $place = $1;
	chomp $place;

	$content =~ s|.*?<TR>(?:\s*<[^>]+>)*\s*([^<]+)\s<.*?</TR>||is;
	my $id = $1;
	chomp $id;

	$content =~ s|.*?conditions at.*?</TD>||is;

	$content =~ s|.*?<OPTION SELECTED>\s+([^<]+)\s<OPTION>.*?</TR>||s;
	my $time = $1;
	$time =~ s/-//g;
	$time =~ s/\s+/ /g;

	$content =~ s|\s(.*?)<TD COLSPAN=2>||s;
	my $features = $1;

	while ($features =~ s|.*?<TD ALIGN[^>]*>(?:\s*<[^>]+>)*\s+([^<]+?)\s+<.*?<TD>(?:\s*<[^>]+>)*\s+([^<]+?)\s<.*?/TD>||s) {
	    my ($f,$v) = ($1, $2);
	    chomp $f; chomp $v;
	    $feat{$f} = $v;
	}

	$content =~ s|.*?>(\d+\S+\s+\(\S+\)).*?</TD>||s;  # max temp;
	$max_temp = $1;
	$content =~ s|.*?>(\d+\S+\s+\(\S+\)).*?</TD>||s;  
	$min_temp = $1;

	if ($time) {
	    $result = "$place; $id; last updated: $time";
	    foreach (sort keys %feat) {
		next if $_ eq 'ob';
		$result .= "; $_: $feat{$_}";
	    }
	    my $t = time();
	    $cache{$station} = join $;, $t, $result;
	} else {
	    $result = "I can't find that station code (see http://weather.noaa.gov/weather/curcond.html for locations and codes)";
	}
	return $result;
    }
}

if (0) {
    if (-t STDIN) {
	my $result = Weather::NOAA::get($default);
	$result =~ s/; /\n/g;
	print "\n$result\n\n";
    }
}

1;

