#!/usr/bin/perl

package UAFlight;
use strict;
my $no_usair;

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

sub get_ua_flight_status {
  my ($flt_num, $day, $month) = @_;
  return 'unsupported: requires HTTP::Request and LWP::UserAgent' if $no_usair;

  my $ua = new LWP::UserAgent;
  my ($wkday, $tmonth, $tday, $time, $year) = split /\s+/, localtime;

  $day = $tday unless $day;
  $month = $tmonth unless $month;

  my $req = POST 'http://dps1.usairways.com/cgi-bin/fi',  
  [ FltNum => $flt_num, month => $month, day => $day, page => 'fi', x => 20, y => 23 ];
  return &parse_ua_flt( $ua->request($req)->as_string)."\n";
}

sub parse_ua_flt {
  my $data = join '', @_;

  my ($airline, $flight_num, $date, $retval, $time);
  my ($dep_city, $est_dep_time, $actual_dep_time, $arr_city, $est_arr_time, $actual_arr_time, $arr_time, $s_dep_city, $s_dep_time, $s_bag_claim, $s_dep_gate, $s_arr_city, $s_arr_time, $s_arr_gate, $s_baggage);

  $data =~ s/^.*Airline:.*?\n//gs;
  $data =~ s/^(.*?)<.*\n// and $airline = $1;
  
  $data =~ s/^.*Flight Number:.*?\n//gs;
  $data =~ s/^(.*?)<.*\n// and $flight_num = $1;
  
  $data =~ s/^.*Date of Information:.*?\n//gs;
  $data =~ s/^(.*?)<.*\n// and $date = $1;

  return "can't find that flight" unless $flight_num;

  $retval = "$airline flight $flight_num on $date ";
  
  $data =~ s/^.*Current Time:.*?\n//gs;
  $data =~ s/^(.*?)<.*\n// and $time = $1;
  
  # $retval .= "Current Time:  $time\n";
  
  # "actual flight info"
  # Airport Actual Estimated Remarks 
  # arrival departure arrival departure
  
  # departure 
  $data =~ s/^.*?<A HREF=.*?page=city\">//gs;
  $data =~ s/^(.*?)<.*?\n// and $dep_city = $1;
  
  $data =~ s/^.*\n//;
  $data =~ s/^<BR>\n//;		# field makes no sense - est arr at depart airport
  
  $data =~ s/^.*\n//;
  $data =~ s/^(.*)\n// and $1 ne "<BR>" and $est_dep_time = $1;

  $data =~ s/^.*\n//;
  $data =~ s/^<BR>\n//;		# field makes no sense - actual arr at depart airport
  
  $data =~ s/^.*\n//;
  $data =~ s/^(.*)\n// and $1 ne "<BR>" and $actual_dep_time = $1;

  my $actual = 0;

  if ($actual_dep_time or $est_dep_time) {
    # arrival
    if ($actual_dep_time) {
      $retval .= "left $dep_city at $actual_dep_time";
    } else {
      $retval .= "estimated departure from $dep_city at $est_dep_time";
    }

    $retval .= " ";

    $data =~ s/^.*?<A HREF=.*?page=city\">//gs;
    $data =~ s/^(.*?)<.*\n// and $arr_city = $1;
    
    $data =~ s/^.*?\n//;
    $data =~ s/^(.*)\n// and $1 ne "<BR>" and $est_arr_time = $1;
    
    $data =~ s/^.*?\n//;
    $data =~ s/^<BR>\n//;	# est dep from arr airport?

    $data =~ s/^.*\n//;
    $data =~ s/^(.*)\n// and $1 ne "<BR>" and $actual_arr_time = $1;
    
    $data =~ s/^.*?\n//;
    $data =~ s/^<BR>\n//;	# actual dep from arr aiport
    
    $data =~ s/^.*?\n//;
    $data =~ s/^(\S+)\s+// and $1 ne "<BR>" and $arr_time = $1;

    if ($actual_arr_time =~ /\S/) {
      $retval .= "arrived in $arr_city at $actual_arr_time";
    } else {
      $retval .= "estimated to arrive in $arr_city at $est_arr_time";
    }
    $actual = 1;
  } 

  $data =~ s/^.*Scheduled Flight Information.*?\n//s;

  # dep
  $data =~ s/^.*?<A HREF=.*?page=city\">//gs;

  $data =~ s/^(.*?)<.*\n// and $s_dep_city = $1;

  $data =~ s/^.*\n//;
  $data =~ s/^<BR>\n//;		# field makes no sense - arr at depart airport
  
  $data =~ s/^.*\n//;
  $data =~ s/^(.*)\n// and $1 ne "<BR>" and $s_dep_time = $1;
  
  $data =~ s/^.*\n//;
  $data =~ s/^<BR>\n//; # arr gate from dep airport
  
  $data =~ s/^.*\n//;
  $data =~ s/^(.*)\n// and $1 ne "<BR>" and $s_bag_claim = $1;
  
  $data =~ s/^.*\n//;
  $data =~ s/^(.*)\n// and $1 ne "<BR>" and $s_dep_gate = $1;
  
  # arr
  $data =~ s/^.*?<A HREF=.*?page=city\">//gs;
  $data =~ s/^(.*?)<.*\n// and $s_arr_city = $1;

  $data =~ s/^.*\n//;
  $data =~ s/^(.*)\n// and $1 ne "<BR>" and $s_arr_time = $1;
  
  $data =~ s/^.*\n//;
  $data =~ s/^<BR>\n//;		
  
  $data =~ s/^.*\n//;
  $data =~ s/^(.*)\n// and $1 ne "<BR>" and $s_arr_gate = $1;
  
  $data =~ s/^.*\n//;
  $data =~ s/^(.*)\n// and $1 ne "<BR>" and $s_baggage = $1;

  if (!$actual) {
    $retval .= "is scheduled to leave $s_dep_city at $s_dep_time ";
    $retval .= "from gate $s_dep_gate " if $s_dep_gate;
    $retval .= "and arrive in $s_arr_city at $s_arr_time ";
    $retval .= "at gate $s_arr_gate" if $s_arr_gate;
  }
  return $retval;
}

"A true value.";
