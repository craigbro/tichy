#!/bin/bash
wget http://www.4q.cc/vin/ >& /dev/null
start=$(grep -n "<\!--start random content script-->" index.html)
end=$(grep -n "<\!--end random content script-->" index.html)

start=${start%:*}
end=${end%:*}
command=$(($start+2))
command=$(echo $command,$(($end-1))!d)

contents=$(cat index.html | sed $command)
echo "$contents" | sed 's/Vin Diesel/Webcheckout/g;s/Vin/WCO/g;s/Diesel/WebCheckout/g'
rm index.html

