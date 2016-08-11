#!/bin/bash

#This script pulls IPMI data from my supermicro motherboard
#in order to show temperatures and fan speed.

#The time we are going to sleep between readings
#Also used to calculate the current usage on the interface
#30 seconds seems to be ideal, any more frequent and the data
#gets really spikey.  Since we are calculating on total octets
#you will never loose data by setting this to a larger value.
sleeptime=30

#servers=(172.16.1.231 172.16.1.232 172.16.1.233)
servers=(172.16.1.231)

#Command we will be using is ipmi tool - sudo apt-get install ipmitool

#Sample Data
#CPU Temp         | 47 degrees C      | ok
#System Temp      | 35 degrees C      | ok
#Peripheral Temp  | 48 degrees C      | ok
#PCH Temp         | 51 degrees C      | ok
#VRM Temp         | 43 degrees C      | ok
#DIMMA1 Temp      | 35 degrees C      | ok
#DIMMA2 Temp      | 33 degrees C      | ok
#DIMMB1 Temp      | 32 degrees C      | ok
#DIMMB2 Temp      | 31 degrees C      | ok
#FAN1             | no reading        | ns
#FAN2             | 500 RPM           | ok
#FAN3             | 1000 RPM          | ok
#FAN4             | 600 RPM           | ok
#FANA             | 500 RPM           | ok
#Vcpu             | 1.77 Volts        | ok
#VDIMM            | 1.31 Volts        | ok
#12V              | 11.85 Volts       | ok
#5VCC             | 4.97 Volts        | ok
#3.3VCC           | 3.31 Volts        | ok
#VBAT             | 3.02 Volts        | ok
#AVCC             | 3.30 Volts        | ok
#VSB              | 3.25 Volts        | ok
#Chassis Intru    | 0x00              | ok

get_ipmi_data () {
    COUNTER=0
    while [  $COUNTER -lt 4 ]; do
        #Get ipmi data
        echo "processing $1"
        ipmitool -H $1 -U ethan -P lighthouse sdr > tempdatafile
        cputemp=`cat tempdatafile | grep "CPU Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        systemtemp=`cat tempdatafile | grep "System Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        periphtemp=`cat tempdatafile | grep "Peripheral Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        pchtemp=`cat tempdatafile | grep "PCH Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        vrmtemp=`cat tempdatafile | grep "VRM Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        dimma1temp=`cat tempdatafile | grep "DIMMA1 Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        dimma2temp=`cat tempdatafile | grep "DIMMA2 Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        dimmb1temp=`cat tempdatafile | grep "DIMMB1 Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        dimmb2temp=`cat tempdatafile | grep "DIMMB2 Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        #fan2=`cat tempdatafile | grep "FAN2" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        #fan3=`cat tempdatafile | grep "FAN3" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        #fan4=`cat tempdatafile | grep "FAN4" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        fana=`cat tempdatafile | grep "FANA" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        rm tempdatafile
        
        #if [[ $cputemp -le 0 || $systemtemp -le 0 || $periphtemp -le 0 || $pchtemp -le 0 || $vrmtemp -le 0 || $dimma1temp -le 0 || $dimma2temp -le 0 || $dimmb1temp -le 0 || $dimmb2temp -le 0 || $fan2 -le 0 || $fan3 -le 0 || $fan4 -le 0 || $fana -le 0 ]]; 
        if [[ $cputemp -le 0 || $systemtemp -le 0 || $periphtemp -le 0 || $pchtemp -le 0 || $vrmtemp -le 0 || $dimma1temp -le 0 || $dimma2temp -le 0 || $dimmb1temp -le 0 || $dimmb2temp -le 0 || $fana -le 0 ]]; 
        	then
                echo "Retry getting data - received some invalid data from the read"
            else
                #We got good data - exit this loop
                COUNTER=10
        fi
        let COUNTER=COUNTER+1 
    done
} 

print_data () {
    echo "CPU Temperature: $cputemp"
    echo "System Temperature: $systemtemp"
    echo "Peripheral Temperature: $periphtemp"
    echo "PCH Temperature: $pchtemp"
    echo "VRM Temperature: $vrmtemp"
    echo "DIMMA1 Temperature: $dimma1temp" 
    echo "DIMMA2 Temperature: $dimma2temp"
    echo "DIMMB1 Temperature: $dimmb1temp"
    echo "DIMMB2 Temperature: $dimmb2temp"
#    echo "Fan2 Speed: $fan2"
#    echo "Fan3 Speed: $fan3"
#    echo "Fan4 Speed: $fan4"
    echo "FanA Speed: $fana"
}

write_data () {
    #Write the data to the database

    host=""
    if [ $1 = "172.16.1.231" ]; then
      host="proxmox01"
      echo "change"
    fi
    echo "sending data for $host"
    exit
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=cputemp value=$cputemp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=systemtemp value=$systemtemp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=periphtemp value=$periphtemp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=pchtemp value=$pchtemp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=vrmtemp value=$vrmtemp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=dimma1temp value=$dimma1temp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=dimma2temp value=$dimma2temp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=dimmb1temp value=$dimmb1temp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=dimmb2temp value=$dimmb2temp"
#    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=fan2 value=$fan2"
#    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=fan3 value=$fan3"
#    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=fan4 value=$fan4"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=$1,sensor=fana value=$fana"
}

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do
    #Sleep between readings
    sleep "$sleeptime"
    
    for server in "${servers[@]}"; do
      get_ipmi_data $server
    
    #if [[ $cputemp -le 0 || $systemtemp -le 0 || $periphtemp -le 0 || $pchtemp -le 0 || $vrmtemp -le 0 || $dimma1temp -le 0 || $dimma2temp -le 0 || $dimmb1temp -le 0 || $dimmb2temp -le 0 || $fan2 -le 0 || $fan3 -le 0 || $fan4 -le 0 || $fana -le 0 ]]; 
    if [[ $cputemp -le 0 || $systemtemp -le 0 || $periphtemp -le 0 || $pchtemp -le 0 || $vrmtemp -le 0 || $dimma1temp -le 0 || $dimma2temp -le 0 || $dimmb1temp -le 0 || $dimmb2temp -le 0 || $fana -le 0 ]]; 
    	then
            echo "Skip this datapoint - something went wrong with the read"
            
        else
            #Output console data for future reference
            print_data
            write_data $server
    fi
    done
done
