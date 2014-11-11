#
# metar -- infobot module for METAR Aviation Routine Weather Report
#          based roughly on example script from Geo::METAR.
#
#          hacked up by Rich Lafferty (mendel) <mendel@pobox.com>. 
#

# minor mods by kevin lenzo (oznoid) <lenzo@cs.cmu.edu>
#  -- package, BEGIN, eval checks
# added status line if LWP isn't there 02-aug-99

# minor mod by Lazarus Long <lazarus@frontiernet.net>
# due to "http://tcsv5.nws.noaa.gov/cgi-bin/mgetmetar.pl?cccc="
# no longer working.

package metar;

my $no_metar;

BEGIN {
    eval "use Geo::METAR";
    if ($@) { $no_metar++};
    eval "use LWP::UserAgent";
    if ($@) { $no_metar++};
}

sub metar::get { 
    my $line = shift;
    return '' unless $line =~ /^metar (.*)/;
    if ($no_metar) {
	&status("METAR function requires LWP::UserAgent and Geo::METAR");
	return '';
    }

    my $site_id = uc($1);
    if ($site_id !~ /^[A-Z]{4,5}$/) {
	return "that doesn't look like a valid METAR code";
    }

    # METAR web-resource.
    my $metar_url = "http://weather.noaa.gov/cgi-bin/mgetmetar.pl?cccc=";

    # Grab METAR report from Web.   
    my $agent = new LWP::UserAgent;
    my $grab = new HTTP::Request GET => $metar_url . $site_id;

    my $reply = $agent->request($grab);
    
    # If it can't find it, assume luser error :-)
    if (!$reply->is_success) {
        return "$site_id doesn't seem to exist; try a 4-letter station code (like KAGC)";
    }  
    
    # extract METAR from incredibly and painfully verbose webpage
    my $webdata = $reply->as_string;
    $webdata =~ m/($site_id\s\d+Z.*?)</s;    
    my $metar = $1;                       
     
    # Sane?
    return "Data for $site_id not available, try later." if length($metar) < 10;
    
    # Process raw METAR data
    my $report = new Geo::METAR;
    $report->debug(0);
    $report->metar($metar);
    
    # Generate response. Messy as hell, but it works. :-)
    # Don't rely on Geo::METAR docs for variable names. It's not
    # even close in some cases.
    #
    # oh, and talk about annoying:
    #        } elsif ($tok =~ /K[A-Z]{3,3}/) {
    #          $self->{site} = $tok;
    # the WORLD is NOT the UNITED STATES. We can't rely on $foo->{site},
    # since it only grabs American (K-prefix) SITE_IDs.

    my $response = "$report->{TYPE} ";
    $response .= "($report->{MOD}) " if $report->MOD;
    $response .= "for $site_id at $report->{DATE} $report->{TIME}: Winds $report->{WIND_KTS} ";

    $response .= "to $report->{WIND_KTS_GUST} " if $report->WIND_KTS_GUST;

    $response .= "at $report->{WIND_DIR_DEG} ($report->{WIND_DIR_ENG}). Temp $report->{C_TEMP}C/$report->{F_TEMP}F and dewpoint $report->{C_DEW}C/$report->{F_DEW}F. Visibility $report->{visibility}. Weather conditions ";

    $response .= join(' ', @{$report->{weather}}) ? join(' ', @{$report->{weather}}) : "not available";  # Most METAR puts this in 'conditions' ({sky}).
   
    $response .= ". Altimeter ";
    $response .= $report->{alt} ? "$report->{alt}. " : "not available. ";

    $response .= "Cloud ";
    $response .= join(' ', @{$report->{sky}});

    $response .= ". Have a nice flight.";   # :-)

    return $response;
}

1;
