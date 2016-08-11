#!/bin/bash
#
# Uses snmpwalk to grab metrics from a synology nas and
# then sends them to a defined graphite server.
#
# Based on work by: Tim Smith - 7/20/2015
# Based on work by: Josh Behrends - 04/29/2013

# variables
Host="ds02"
HostIP="172.16.1.16"
SNMP_Community="public"

# snmpwalk the device
interface=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.1 | awk '{print $4}'| tr -d '"') )
ifHCOutOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.10 | awk '{print $4}') )
ifHCInOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.31.1.1.1.6 | awk '{print $4}') )
sysUpTime=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.2.1.1.3 | sed 's/.*[(]\([0-9]*\)[)].*/\1/')
memTotalReal=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.5 | awk '{print $4}')
memAvailReal=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP 1.3.6.1.4.1.2021.4.6 | awk '{print $4}')
allocationUnits=$(snmpwalk -On -v 2c -c $SNMP_Community $HostIP .1.3.6.1.2.1.25.2.3.1.4.50 | awk '{print $4}')
totalStorage=`expr $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP .1.3.6.1.2.1.25.2.3.1.5.50 | awk '{print $4}') \* $allocationUnits`
usedStorage=`expr $(snmpwalk -On -v 2c -c $SNMP_Community $HostIP .1.3.6.1.2.1.25.2.3.1.6.50 | awk '{print $4}') \* $allocationUnits`
availableStorage=`expr $totalStorage - $usedStorage`

# output to graphite from walked metrics above.
#for (( i=0; i<${#interface[*]}; i=i+1 )); do
#  echo "$MetricRoot"."$Host".interface."${interface[$i]}".ifHCOutOctets" ${ifHCOutOctets[$i]} `date +%s`" #| nc -w 1 ${CarbonServer} ${CarbonPort};
#  echo "$MetricRoot"."$Host".interface."${interface[$i]}".ifHCInOctets" ${ifHCInOctets[$i]} `date +%s`" #| nc -w 1 ${CarbonServer} ${CarbonPort};
#done

curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds02,metric=uptime value=$(($sysUpTime/100))"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds02,metric=memTotalReal value=$memTotalReal"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds02,metric=memAvailReal value=$memAvailReal"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds02,metric=totalStorage value=$totalStorage"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds02,metric=usedStorage value=$usedStorage"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=ds02,metric=availableStorage value=$availableStorage" #Work around for influx/grafana limitation


