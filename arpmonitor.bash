#!/usr/local/bin/bash

## Define Initial ARP result file
#
initialarp="/usr/local/bin/initialarp.dat"
chkarp="/usr/local/bin/arpscanning.dat"

## What is the percentage that should be reachable on IP adresses?
#
minpercentage=70

## Can Mac adresses be different? (0=No / 1 = Yes)
#
macdifferent=0

## Get the initial Mac adresses of the network (Only Once and save it)
#
arp-scan -I bge0 --rtt --format='|${ip;-15}|${mac}|${rtt;8}|' 192.30.177.0/24 > $initialarp

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

arp-scan -I bge0 --rtt --format='|${ip;-15}|${mac}|${rtt;8}|' 192.30.177.0/24 > $chkarp

## Insert the arp file into an array, and break each line with WhiteSpace
#
IFS=$'\n' read -d '' -r -a chklines < $chkarp

## Debug purpeses, see all the lines
#
#echo "${lines[@]}"

printf "line 1: %s\n" "${chklines[0]}"
printf "line 5: %s\n" "${chklines[4]}"

for chkline in "${chklines[@]}"
do
   # do whatever on "$chkline" here
   echo $chkline
   IFS='|' read -ra CHKADDR <<< "$chkline"

   echo "${CHKADDR[1]}"
   echo "${CHKADDR[2]}"
done
