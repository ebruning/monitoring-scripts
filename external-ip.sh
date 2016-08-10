#!/bin/sh

sleeptime=21600

while :
do
  result=$(wget http://ipinfo.io/ip -qO -)
  
	curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "external,metric=address value=$result"

  sleep "$sleeptime"
done

