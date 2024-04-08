#!/usr/local/bin/bash

## Define Initial ARP result file
#
initialarp="/usr/local/bin/initialarp.dat"
chkarp="/usr/local/bin/arpscanning.dat"
armonitorplog="/var/log/arpmonitor.log"
LANinterface="bge0"

## What is the percentage that should be reachable on IP adresses?
#
minpercentage=70

## Can Mac adresses be different? (0=No / 1 = Yes)
#
macdifferent=0

echo "Start the Arp Monitor routine, first do a initial arp-scan" > armonitorplog

## Get the initial Mac adresses of the network (Only Once and save it)
#
arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|${rtt;8}|' 192.30.177.0/24 > $initialarp

## Insert the arp initial file into an array, and break each line with WhiteSpace
#
IFS=$'\n' read -d '' -r -a initiallines < $initialarp


count=0
for initialline in "${initiallines[@]}"
do
   # do whatever on "$initialline" here
   #echo $initialline
   IFS='|' read -ra INITIALADDR <<< "$initialline"

   echo "IP:  ${INITIALADDR[1]}"
   echo "Mac: ${INITIALADDR[2]}"
   echo "$count"
   InitialIP[$count]=${INITIALADDR[1]}
   InitialMac[$count]=${INITIALADDR[2]}

   echo "Initial IP: ${InitialIP[$count]}"
   echo "Initial Mac: ${InitialMac[$count]}"
   count=$((count + 1))
done

## Sleep before doing checkups
#
sleep 1

arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|${rtt;8}|' 192.30.177.0/24 > $chkarp

## Insert the arp file into an array, and break each line with WhiteSpace
#
IFS=$'\n' read -d '' -r -a chklines < $chkarp

## Debug purpeses, see all the lines
#
#echo "${lines[@]}"

#printf "line 1: %s\n" "${chklines[0]}"
#printf "line 5: %s\n" "${chklines[4]}"

## Loop through the lines of interval arp-scan so we can see if the ip adresses and mac adresses still match
#
let countmacok=0
let countmactotal=0
let countmacfault=0

for chkline in "${chklines[@]}"
do
   # do whatever on "$chkline" here
   echo $chkline
   IFS='|' read -ra CHKADDR <<< "$chkline"

   chkIP=${CHKADDR[1]}
   chkMac=${CHKADDR[2]}

   echo $chkIP
   echo $chkMac

   if [ "$chkIP" != "" ]; then
     ## Check the IP adresses and Mac adresses with the initial Arp-scan
     #
     let tellen=0
     while [ $tellen -lt $count ]; do
       #echo "Checking IP and Mac against original IP and Mac $tellen (${chkIP} : ${InitialIP[$tellen]} / ${chkMac} : ${InitialMac[$tellen]} "

       ## Yes you dumb fuck, for filling a string in Bash, you dont enter $ in front of it!
       #
       initIP=${InitialIP[$tellen]}

       if [ "$chkIP" = "$initIP" ]; then
         echo "found $chkIP - $initIP - Checking if Mac adress is correct...."
         initMac=${InitialMac[$tellen]}
         if [ "$chkMac" = "$initMac" ]; then
           echo "Mac adress: $chkMac is the same as: $initMac"
           countmacok=$((countmacok + 1))
         else
           echo "Mac adress: $chkMac is different: $initMac"
           countmacfault=$((countmacfault + 1))
         fi
         countmactotal=$((countmactotal + 1))
       fi
       let tellen=tellen+1
     done
  fi
done

echo "CountMac Total: $countmactotal"
echo "CountMac OK: $countmacok"
