#!/bin/bash
#
# Uses snmpwalk to grab metrics from a synology nas and
# then sends them to a defined graphite server.
#
# Based on work by: Tim Smith - 7/20/2015
# Based on work by: Josh Behrends - 04/29/2013

# Variables
sleeptime=30
servers=(172.16.1.15 172.16.1.16)
SNMP_Community="public"

clear_data () {
  interface=""
  ifHCOutOctets=""
  ifHCInOctets=""
  sysUpTime=""
  load1=""
  load5=""
  load15=""
  cpufanstatus=""
  systemfanstatus=""
  powerstatus=""
  systemstatus=""
  temperature=""
  memTotalReal=""
  memAvailReal=""
  memBuffer=""
  memShared=""
  memCached=""
  allocationUnits=""
  totalStorage=""
  usedStorage=""
  availableStorage=""
}

print_data () {
  echo $interface
  echo $ifHCOutOctets
  echo $ifHCInOctets
  echo $sysUpTime
  echo $memTotalReal
  echo $memAvailReal
  echo $allocationUnits
  echo $totalStorage
  echo $usedStorage
  echo $availableStorage

  if [ $1 = "172.16.1.15" ]; then
    echo $load1
    echo $load5
    echo $load15
    echo $cpufanstatus
    echo $systemfanstatus
    echo $powerstatus
    echo $systemstatus
    echo $temperature
    echo $memBuffer
    echo $memShared
    echo $memCached
  fi
}

get_data () {
  echo "fetching data for $1"
  interface=( $(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.2.1.31.1.1.1.1 | awk '{print $4}'| tr -d '"') )
  ifHCOutOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.2.1.31.1.1.1.10 | awk '{print $4}') )
  ifHCInOctets=( $(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.2.1.31.1.1.1.6 | awk '{print $4}') )
  sysUpTime=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.2.1.1.3 | sed 's/.*[(]\([0-9]*\)[)].*/\1/')
  memTotalReal=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.2021.4.5 | awk '{print $4}')
  memAvailReal=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.2021.4.6 | awk '{print $4}')
  availableStorage=`expr $totalStorage - $usedStorage`

    if [ $1 = "172.16.1.15" ]; then
    load1=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.2021.10.1.3.1 | awk '{print $4}'| tr -d '"')
    load5=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.2021.10.1.3.2 | awk '{print $4}'| tr -d '"')
    load15=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.2021.10.1.3.3 | awk '{print $4}'| tr -d '"')
    cpufanstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.6574.1.4.2.0 | awk '{print $4}'| tr -d '"')
    systemfanstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.6574.1.4.1.0 | awk '{print $4}'| tr -d '"')
    powerstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.6574.1.3.0 | awk '{print $4}'| tr -d '"')
    systemstatus=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.6574.1.1.0 | awk '{print $4}'| tr -d '"')
    temperature=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.6574.1.2.0 | awk '{print $4}'| tr -d '"')
    memBuffer=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.2021.4.14 | awk '{print $4}')
    memShared=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.2021.4.13 | awk '{print $4}')
    memCached=$(snmpwalk -On -v 2c -c $SNMP_Community $1 1.3.6.1.4.1.2021.4.15 | awk '{print $4}')
    allocationUnits=$(snmpwalk -On -v 2c -c $SNMP_Community $1 .1.3.6.1.2.1.25.2.3.1.4.50 | awk '{print $4}')
    totalStorage=`expr $(snmpwalk -On -v 2c -c $SNMP_Community $1 .1.3.6.1.2.1.25.2.3.1.5.50 | awk '{print $4}') \* $allocationUnits`
    usedStorage=`expr $(snmpwalk -On -v 2c -c $SNMP_Community $1 .1.3.6.1.2.1.25.2.3.1.6.50 | awk '{print $4}') \* $allocationUnits`
  fi
  
  if [ $1 = "172.16.1.16" ]; then
    allocationUnits=$(snmpwalk -On -v 2c -c $SNMP_Community $1 .1.3.6.1.2.1.25.2.3.1.4.49 | awk '{print $4}')
    totalStorage=`expr $(snmpwalk -On -v 2c -c $SNMP_Community $1 .1.3.6.1.2.1.25.2.3.1.5.49 | awk '{print $4}') \* $allocationUnits`
    usedStorage=`expr $(snmpwalk -On -v 2c -c $SNMP_Community $1 .1.3.6.1.2.1.25.2.3.1.6.49 | awk '{print $4}') \* $allocationUnits`
  fi
}

write_data () {
  echo "writing data for $1"
  
  if [ $1 = "172.16.1.15" ]; then
    host="ds01"
  elif [ $1 = "172.16.1.16" ]; then
    host="ds02"
  else
    host="unknown"
  fi

  curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=uptime value=$(($sysUpTime/100))"
  curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=memTotalReal value=$memTotalReal"
  curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=memAvailReal value=$memAvailReal"
  curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=totalStorage value=$totalStorage"
  curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=usedStorage value=$usedStorage"
  curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=availableStorage value=$availableStorage" #Work around for influx/grafana limitation  
  
  if [ $1 = "172.16.1.15" ]; then
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=load1 value=$load1"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=load5 value=$load5"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=load15 value=$load15"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=temperature value=$temperature"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=cpufanstatus value=$cpufanstatus"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=systemfanstatus value=$systemfanstatus"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=powerstatus value=$powerstatus"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=systemstatus value=$systemstatus"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=memBuffer value=$memBuffer"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=memShared value=$memShared"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "nas,host=$host,metric=memCached value=$memCached"
  fi
  clear_data
}


#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do
    sleep "$sleeptime"
    for server in "${servers[@]}"; do
      get_data $server
      print_data $server 
      write_data $server
    done
done



