#!/usr/local/bin/bash

## Define Initial ARP result file
#
initialarp="/usr/local/bin/initialarp.dat"
initialdedup="/usr/local/bin/initialarpdedup.dat"
chkarp="/usr/local/bin/arpscanning.dat"
chkdeduparp="/usr/local/bin/arpdedupscanning.dat"
armonitorlog="/var/log/arpmonitor.log"
LANinterface="bge0"

## What is the percentage that should be reachable on IP adresses?
#
minpercentage=70

## Can Mac adresses be different? (0=No / 1 = Yes)
#
macdifferent=0

## if yes, how many percent?
macdiffpercent=80

echo "Start the Arp Monitor routine, first do a initial arp-scan" > $armonitorlog

## Get the initial Mac adresses of the network (Only Once and save it)
#
arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|' 192.30.177.0/24 > $initialarp

#arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|' 192.30.177.0/24 | awk '/([a-f0-9]{2}:){5}[a-f0-9]{2}/&&!seen[$1]++{print $1}' > $initialarp

echo "Remove the possible double entry;s from the initial ARP Scan" > $armonitorlog

## Insert the arp initial file into an array, and break each line with WhiteSpace
#
IFS=$'\n' read -d '' -r -a initiallines < $initialarp

## Remove the double entry's
#
count=0
initialduplicates=0
echo "## Deduplication of initial Arp-scan results" > $initialdedup
for initialline in "${initiallines[@]}"
do
  dedup[$count]=$initialline

  let tellen=0
  let found=0
  while [ $tellen -lt $count ]; do
    remember=${dedup[$tellen]}

    ## Debug purposes
    #
    #echo "Remember: $remember --> $initialline --> $tellen"

    if [ "$remember" = "$initialline" ]; then
      let found=1
      echo "## Found a duplicate line: $initialline #########################" >> $armonitorlog
    fi
    let tellen=tellen+1
  done
  if (( $found == 0 )) ; then
    ## Save this line it is unique
    #
    echo $initialline >> $initialdedup
  else
    ## Count the duplicates
    #
    initialduplicates=$((initialduplicates + 1))
  fi
  count=$((count + 1))
  #sleep 1
done
initialcount=$count

echo "Loop through each line of initial arp-scan" >> $armonitorlog

IFS=$'\n' read -d '' -r -a initiallines < $initialdedup

count=0
countfilledlines=0

for initialline in "${initiallines[@]}"
do
   # do whatever on "$initialline" here
   #echo $initialline
   IFS='|' read -ra INITIALADDR <<< "$initialline"

   echo "initial IP:  ${INITIALADDR[1]} - count: $count" >> $armonitorlog
   echo "initial Mac: ${INITIALADDR[2]} - count: $count" >> $armonitorlog

   InitialIP[$count]=${INITIALADDR[1]}
   InitialMac[$count]=${INITIALADDR[2]}
   fullempty=${INITIALADDR[1]}

   if [ "$fullempty" != "" ]; then
      ## Only count the filled lines
      #
      countfilledlines=$((countfilledlines + 1))
      echo "Filled InitialIP counted: ${InitialIP[$count]} - ${InitialMac[$count]}" >> $armonitorlog
   fi

   #echo "Initial IP: ${InitialIP[$count]}"
   #echo "Initial Mac: ${InitialMac[$count]}"

   count=$((count + 1))
done

## Sleep before doing checkups
#
echo "Sleeping before interval checking...." >> $armonitorlog
sleep 1

arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|' 192.30.177.0/24 > $chkarp

## Insert the arp file into an array, and break each line with WhiteSpace
#
IFS=$'\n' read -d '' -r -a chklines < $chkarp

## Remove the double entry's
#
count=0
chkduplicates=0
echo "## Deduplication of Returning Arp-scan results" > $chkdeduparp
for chkline in "${chklines[@]}"
do
  chkdedup[$count]=$chkline

  let tellen=0
  let found=0
  while [ $tellen -lt $count ]; do
    remember=${chkdedup[$tellen]}

    ## Debug purposes
    #
    #echo "Remember: $remember --> $initialline --> $tellen"

    if [ "$remember" = "$chkline" ]; then
      let found=1
      echo "## Found a duplicate line: $chkline #########################" >> $armonitorlog
    fi
    let tellen=tellen+1
  done
  if (( $found == 0 )) ; then
    ## Save this line it is unique
    #
    echo $chkline >> $chkdeduparp
  else
    ## Count the duplicates
    #
    chkduplicates=$((chkduplicates + 1))
  fi
  count=$((count + 1))
  #sleep 1
done

## Read the deduplicated file
#
IFS=$'\n' read -d '' -r -a chklines < $chkdeduparp

## Debug purpeses, see all the lines
#
#echo "${lines[@]}"

## Loop through the lines of interval arp-scan so we can see if the ip adresses and mac adresses still match
#
let countmacok=0
let countmactotal=0
let countmacfault=0

for chkline in "${chklines[@]}"
do
   # do whatever on "$chkline" here
   echo $chkline >> $armonitorlog
   IFS='|' read -ra CHKADDR <<< "$chkline"

   chkIP=${CHKADDR[1]}
   chkMac=${CHKADDR[2]}

   #echo $chkIP
   #echo $chkMac

   if [ "$chkIP" != "" ]; then
     ## Check the IP adresses and Mac adresses with the initial Arp-scan
     #
     let tellen=0
     while [ $tellen -lt $count ]; do
       ## Little less logging may be done
       #
       #echo "Checking IP and Mac against original IP and Mac $tellen (${chkIP} : ${InitialIP[$tellen]} / ${chkMac} : ${InitialMac[$tellen]} " >> $armonitorlog

       initIP=${InitialIP[$tellen]}

       if [ "$chkIP" = "$initIP" ]; then
         echo "found $chkIP - $initIP - Checking if Mac adress is correct...." >> $armonitorlog
         initMac=${InitialMac[$tellen]}
         if [ "$chkMac" = "$initMac" ]; then
           echo "Mac adress: $chkMac is the same as: $initMac" >> $armonitorlog
           countmacok=$((countmacok + 1))
         else
           echo "Mac adress: $chkMac is different: $initMac" >> $armonitorlog
           countmacfault=$((countmacfault + 1))
         fi
         countmactotal=$((countmactotal + 1))
       fi
       let tellen=tellen+1
     done
  fi
done

echo "Initial ARP count with duplicates: $initialcount"
echo "CountMac Total: $countmactotal"
echo "CountMac OK: $countmacok"
echo "CountMac Fault: $countmacfault"
echo "Count Filled Lines: $countfilledlines"
echo "Initial Duplicate lines found: $initialduplicates"
echo "Re-accuring Duplicates found: $chkduplicates"

echo "Initial ARP count with duplicates: $initialcount" >> $armonitorlog
echo "CountMac Total: $countmactotal" >> $armonitorlog
echo "CountMac OK: $countmacok" >> $armonitorlog
echo "CountMac Fault: $countmacfault" >> $armonitorlog
echo "Count Filled Lines: $countfilledlines" >> $armonitorlog
echo "Initial Duplicate lines found: $initialduplicates" >> $armonitorlog
echo "Re-accuring Duplicates found: $chkduplicates" >> $armonitorlog

howmanyprocent=$((100*$countmacok/$countfilledlines))
echo "How many percent is missing from the initial arp-scan: $howmanyprocent"
echo "How many percent is missing from the initial arp-scan: $howmanyprocent" >> $armonitorlog

## Check if the percentage is less than the minimum percentage, if it is less take action.
#
let takeaction=0
if [ $howmanyprocent -lt $minpercentage ]; then
  ## Less than the minimal percentage is there, take action!
  echo "The found ip adres percentage: $howmanyprocent is lower than $minpercentage, take action!" >> $armonitorlog
  let takeaction=1
else
  ## Within percentage, all is ok!
  echo "The found ip adres percentage: $howmanyprocent is higher than $minpercentage, all is well!" >> $armonitorlog
  takeaction=0
fi

## Check if an mac adress may change
#
if [ $macdifferent -eq 0 ]; then
  ## All mac adresses must be the same on the same ip adressses
  echo "All Mac adresses MUST be the same, check if there are faulty MAc adresses" >> $armonitorlog
  if [ $countmacfault -gt 0 ]; then
    ## There is a problem, an mac adress is different
    echo "Number of faulty mac adresses: $countmacfault, None is the Rule, take action!" >> $armonitorlog
    let takeaction=1
  else
    echo "All Mac adresses are the same as the initial readout by arp-scan" >> $armonitorlog
  fi
else
  ## Yes there may be a difference, but how many percent?
  ## $macdiffpercent
  #
  echo "Not all Mac adresses in the network have to be exactly the same, a minimal percentage is given: $diffprocent" >> $armonitorlog
  diffprocent=$((100*$countmacok/$countmactotal))
  if [ $diffprocent -lt $macdiffpercent]; then
    ## Less than the minimal percentage is there, take action!
    echo "The Mac pass percentage: $macdiffpercent is lower than $diffprocent, take action!" >> $armonitorlog
    let takeaction=1
  else
    ## Within percentage, all is ok!
    echo "The Mac pass percentage: $howmanyprocent is higher than $minpercentage, all is well!" >> $armonitorlog
    let takeaction=0
  fi
fi

echo "Do we need to take action? : $takeaction"
