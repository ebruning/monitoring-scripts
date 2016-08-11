#!/bin/bash
#
# Uses snmpwalk to grab metrics from a synology nas and
# then sends them to a defined graphite server.
#
# Based on work by: Tim Smith - 7/20/2015
# Based on work by: Josh Behrends - 04/29/2013

# variables
CarbonServer="localhost"
CarbonPort="2003"
MetricRoot="servers"
Host="ds01"
HostIP="172.16.1.15"
SNMP_Community="public"

# snmpwalk the device
interface=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.1 | awk '{print $4}'| tr -d '"') )
ifHCOutOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.10 | awk '{print $4}') )
ifHCInOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.6 | awk '{print $4}') )
sysUpTime=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.1.3 | sed 's/.*[(]\([0-9]*\)[)].*/\1/')
load1=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.10.1.3.1 | awk '{print $4}'| tr -d '"')
load5=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.10.1.3.2 | awk '{print $4}'| tr -d '"')
load15=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.10.1.3.3 | awk '{print $4}'| tr -d '"')
cpufanstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.6574.1.4.2.0 | awk '{print $4}'| tr -d '"')
systemfanstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.6574.1.4.1.0 | awk '{print $4}'| tr -d '"')
powerstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.6574.1.3.0 | awk '{print $4}'| tr -d '"')
systemstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.6574.1.1.0 | awk '{print $4}'| tr -d '"')
temperature=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.6574.1.2.0 | awk '{print $4}'| tr -d '"')
memTotalReal=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.5 | awk '{print $4}')
memAvailReal=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.6 | awk '{print $4}')
memBuffer=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.14 | awk '{print $4}')
memShared=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.13 | awk '{print $4}')
memCached=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.15 | awk '{print $4}')
allocationUnits=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP .1.3.6.1.2.1.25.2.3.1.4.50 | awk '{print $4}')
totalStorage=`expr $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP .1.3.6.1.2.1.25.2.3.1.5.50 | awk '{print $4}') \* $allocationUnits`
usedStorage=`expr $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP .1.3.6.1.2.1.25.2.3.1.6.50 | awk '{print $4}') \* $allocationUnits`

# output to graphite from walked metrics above.
#for (( i=0; i<${#interface[*]}; i=i+1 )); do
#  echo "$MetricRoot"."$Host".interface."${interface[$i]}".ifHCOutOctets" ${ifHCOutOctets[$i]} `date +%s`" #| nc -w 1 ${CarbonServer} ${CarbonPort};
#  echo "$MetricRoot"."$Host".interface."${interface[$i]}".ifHCInOctets" ${ifHCInOctets[$i]} `date +%s`" #| nc -w 1 ${CarbonServer} ${CarbonPort};
#done

curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=load1 value=$load1"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=load5 value=$load5"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=load15 value=$load15"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=uptime value=$(($sysUpTime/100))"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=temperature value=$temperature"

curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=cpufanstatus value=$cpufanstatus"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=systemfanstatus value=$systemstatus"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=powerstatus value=$powerstatus"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=systemstatus value=$systemstatus"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=memTotalReal value=$memTotalReal"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=memAvailReal value=$memAvailReal"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=memBuffer value=$memBuffer"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=memShared value=$memShared"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=memCached value=$memCached"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=totalStorage value=$totalStorage"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds01,metric=usedStorage value=$usedStorage"


