#!/usr/local/bin/bash

## Define Initial ARP result file
#
initialarp="/usr/local/bin/initialarp.dat"
chkarp="/usr/local/bin/arpscanning.dat"

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

sleep 1

arp-scan -I bge0 --rtt --format='|${ip;-15}|${mac}|${rtt;8}|' 192.30.177.0/24 > $chkarp

#while IFS= read -r line
#do
#  echo "$line"
#done < "$chkarp"

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

#     for i in "${ADDR[@]}"; do
#       # process "$i"
#       echo $i
#  done
#   echo "${ADDR[0]}"
   echo "${CHKADDR[1]}"
   echo "${CHKADDR[2]}"
done
