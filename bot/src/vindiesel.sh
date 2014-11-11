#!/bin/bash
#wget http://www.4q.cc/vin/ >& /dev/null
wget http://mirror.4q.cc/ >& /dev/null
start=$(grep -n "<\!--start random content script-->" index.html)
end=$(grep -n "<\!--end random content script-->" index.html)

start=${start%:*}
end=${end%:*}
command=$(($start+2))
command=$(echo $command,$(($end-1))!d)

contents=$(cat index.html| sed $command)
echo "$contents" 
#rm index.html

