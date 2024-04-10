#!/usr/local/bin/bash

## Define Initial ARP result file
#
initialarp="/home/USB/Data/initialarp.dat"
initialdedup="/home/USB/Data/initialarpdedup.dat"
chkarp="/home/USB/Data/arpscanning.dat"
chkdeduparp="/home/USB/Data/arpdedupscanning.dat"
armonitorlog="/home/USB/Log/arpmonitor.log"
LANinterface="bge0"

## How long do we sleep before doing the next check (in seconds)
## 3600 = 1 hour / 7200 = 2 hours
#
Interval=1

## Debug level
## 0 = None / 1 = Basic / 2 = Averige / 3 = A lot (Keep those MBs coming!)
#
DebugLevel=1

## What is the percentage that should be reachable on IP adresses?
#
minpercentage=90

## Can Mac adresses be different? (0=No / 1 = Yes)
#
macdifferent=0

## if yes, how many percent?
#
macdiffpercent=80

## How much time do we give for the machine to gracefully Shutdown? (in seconds)
#
gracefultime=600

if (( DebugLevel > 0 )); then
  echo "Start the Arp Monitor routine, first do a initial arp-scan" > $armonitorlog
fi

## Get the initial Mac adresses of the network (Only Once and save it)
#
arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|' 192.30.177.0/24 > $initialarp

if (( DebugLevel > 0 )); then
  echo "Remove the possible double entry;s from the initial ARP Scan" > $armonitorlog
fi

## Insert the arp initial file into an array, and break each line with WhiteSpace
#
IFS=$'\n' read -d '' -r -a initiallines < $initialarp

## Remove the double entry's
#
count=0
initialduplicates=0

if (( DebugLevel > 0 )); then
  echo "## Deduplication of initial Arp-scan results" > $initialdedup
fi

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
      if (( DebugLevel > 1 )); then
        echo "## Found a duplicate line: $initialline #########################" >> $armonitorlog
      fi
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
done
initialcount=$count

if (( DebugLevel > 0 )); then
  echo "Loop through each line of initial arp-scan" >> $armonitorlog
fi

IFS=$'\n' read -d '' -r -a initiallines < $initialdedup

count=0
countfilledlines=0

for initialline in "${initiallines[@]}"
do
   # do whatever on "$initialline" here
   #echo $initialline
   IFS='|' read -ra INITIALADDR <<< "$initialline"

   if (( DebugLevel > 1 )); then
     echo "initial IP:  ${INITIALADDR[1]} - count: $count" >> $armonitorlog
     echo "initial Mac: ${INITIALADDR[2]} - count: $count" >> $armonitorlog
   fi

   InitialIP[$count]=${INITIALADDR[1]}
   InitialMac[$count]=${INITIALADDR[2]}
   fullempty=${INITIALADDR[1]}

   if [ "$fullempty" != "" ]; then
      ## Only count the filled lines
      #
      countfilledlines=$((countfilledlines + 1))
      if (( DebugLevel > 0 )); then
        echo "Filled InitialIP counted: ${InitialIP[$count]} - ${InitialMac[$count]}" >> $armonitorlog
      fi
   fi

   #echo "Initial IP: ${InitialIP[$count]}"
   #echo "Initial Mac: ${InitialMac[$count]}"

   count=$((count + 1))
done

## Sleep before doing checkups
#
if (( DebugLevel > 0 )); then
  echo "Sleeping $Interval before next interval check...." >> $armonitorlog
fi
sleep $Interval

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
    if (( DebugLevel > 1 )); then
      echo "Remember: $remember --> $initialline --> $tellen"
    fi

    if [ "$remember" = "$chkline" ]; then
      let found=1
      if (( DebugLevel > 0 )); then
        echo "## Found a duplicate line: $chkline #########################" >> $armonitorlog
      fi
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
if (( DebugLevel > 2 )); then
  echo "${lines[@]}"
fi

## Loop through the lines of interval arp-scan so we can see if the ip adresses and mac adresses still match
#
let countmacok=0
let countmactotal=0
let countmacfault=0

for chkline in "${chklines[@]}"
do
   # do whatever on "$chkline" here
   if (( DebugLevel > 2 )); then
     echo $chkline >> $armonitorlog
   fi

   ## Split the string with delimiter P|pe from string $chkline
   #
   IFS='|' read -ra CHKADDR <<< "$chkline"

   chkIP=${CHKADDR[1]}
   chkMac=${CHKADDR[2]}

   if (( DebugLevel > 2 )); then
     echo $chkIP
     echo $chkMac
   fi

   if [ "$chkIP" != "" ]; then
     ## Check the IP adresses and Mac adresses with the initial Arp-scan
     #
     let tellen=0
     while [ $tellen -lt $count ]; do
       ## Little less logging may be done, lets regulated it with a parameter
       #
       if (( DebugLevel > 2 )); then
         echo "Checking IP and Mac against original IP and Mac $tellen (${chkIP} : ${InitialIP[$tellen]} / ${chkMac} : ${                                                                      InitialMac[$tellen]} " >> $armonitorlog
       fi

       initIP=${InitialIP[$tellen]}

       if [ "$chkIP" = "$initIP" ]; then
         if (( DebugLevel > 0 )); then
           echo "found $chkIP - $initIP - Checking if Mac adress is correct...." >> $armonitorlog
         fi
         initMac=${InitialMac[$tellen]}
         if [ "$chkMac" = "$initMac" ]; then
           if (( DebugLevel > 1 )); then
             echo "Mac adress: $chkMac is the same as: $initMac" >> $armonitorlog
           fi

           countmacok=$((countmacok + 1))
         else
           if (( DebugLevel > 1 )); then
             echo "Mac adress: $chkMac is different: $initMac" >> $armonitorlog
           fi
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

if (( DebugLevel > 0 )); then
  echo "Initial ARP count with duplicates: $initialcount" >> $armonitorlog
  echo "CountMac Total: $countmactotal" >> $armonitorlog
  echo "CountMac OK: $countmacok" >> $armonitorlog
  echo "CountMac Fault: $countmacfault" >> $armonitorlog
  echo "Count Filled Lines: $countfilledlines" >> $armonitorlog
  echo "Initial Duplicate lines found: $initialduplicates" >> $armonitorlog
  echo "Re-accuring Duplicates found: $chkduplicates" >> $armonitorlog
fi

howmanyprocent=$((100*$countmacok/$countfilledlines))
echo "How many percent is missing from the initial arp-scan: $howmanyprocent"
if (( DebugLevel > 0 )); then
  echo "How many percent is missing from the initial arp-scan: $howmanyprocent" >> $armonitorlog
fi

## Check if the percentage is less than the minimum percentage, if it is less take action.
#
let takeaction=0
if [ $howmanyprocent -lt $minpercentage ]; then
  ## Less than the minimal percentage is there, take action!
  if (( DebugLevel > 0 )); then
    echo "The found ip adres percentage: $howmanyprocent is lower than $minpercentage, take action!" >> $armonitorlog
  fi

  let takeaction=1
else
  ## Within percentage, all is ok!
  if (( DebugLevel > 0 )); then
    echo "The found ip adres percentage: $howmanyprocent is higher than $minpercentage, all is well!" >> $armonitorlog
  fi
  takeaction=0
fi

## Check if an mac adress may change
#
if [ $macdifferent -eq 0 ]; then
  ## All mac adresses must be the same on the same ip adressses
  if (( DebugLevel > 0 )); then
    echo "All Mac adresses MUST be the same, check if there are faulty MAc adresses" >> $armonitorlog
  fi

  if [ $countmacfault -gt 0 ]; then
    ## There is a problem, an mac adress is different
    if (( DebugLevel > 0 )); then
      echo "Number of faulty mac adresses: $countmacfault, None is the Rule, take action!" >> $armonitorlog
    fi

    let takeaction=1
  else
    if (( DebugLevel > 0 )); then
      echo "All Mac adresses are the same as the initial readout by arp-scan" >> $armonitorlog
    fi
  fi
else
  ## Yes there may be a difference, but how many percent?
  ## $macdiffpercent
  #
  if (( DebugLevel > 0 )); then
    echo "Not all Mac adresses in the network have to be exactly the same, a minimal percentage is given: $diffprocent" >>                                                                       $armonitorlog
  fi

  diffprocent=$((100*$countmacok/$countmactotal))
  if [ $diffprocent -lt $macdiffpercent]; then
    ## Less than the minimal percentage is there, take action!
    if (( DebugLevel > 0 )); then
      echo "The Mac pass percentage: $macdiffpercent is lower than $diffprocent, take action!" >> $armonitorlog
    fi
    let takeaction=1
  else
    ## Within percentage, all is ok!
    if (( DebugLevel > 0 )); then
      echo "The Mac pass percentage: $howmanyprocent is higher than $minpercentage, all is well!" >> $armonitorlog
    fi

    let takeaction=0
  fi
fi

echo "Do we need to take action (0 = No / 1 = Yes)? : $takeaction"
if (( takeaction > 0 )); then
  if (( DebugLevel > 0 )); then
    echo "Do we need to take action (0 = No / 1 = Yes)? : $takeaction --> Yes! we need to take action!" >> $armonitorlog
  fi

  ## Fill a string to see if there are running Vm's
  #
  RunningVMs=$(VBoxManage list runningvms)
  if (( DebugLevel > 0 )); then
    echo "Found the following machijnes running: $RunningVMs" >> $armonitorlog
  fi
  if [ "$RunningVMs" != "" ]; then
    ## Yes the VM for this user is running, make it shutdown gracefully
    #
    ## First get the machine name the smart way (From the string), we need to split the string on a [space]
    #
    IFS=' ' read -ra VMNAME <<< "$RunningVMs"
    VboxName=${VMNAME[0]}

    if (( DebugLevel > 1 )); then
      echo "Virtual Machine name found: $VboxName"
    fi
    ## First get the machine name the smart way (From the string)
    #
    if (( DebugLevel > 1 )); then
      echo "Pressing ACPI Powerbutton for Virtual Machine:  $VboxName to gracefully shutdown the machine" >> $armonitorlog
    fi
    ResultPWRButton=$(VBoxManage controlvm $VboxName acpipowerbutton)

    if (( DebugLevel > 1 )); then
      echo "Give time for the Virtual Machine:  $VboxName to gracefully shutdown, sleep for $gracefultime seconds" >> $armonitorlog
      echo $ResultPWRButton >> $armonitorlog
    fi
    sleep $gracefultime

    if (( DebugLevel > 1 )); then
      echo "To be fully sure, poweroff the VM : $VboxName"
    fi
    ResultPowerOFF=$(VBoxManage controlvm $VboxName poweroff)
  else
    if (( DebugLevel > 0 )); then
      echo "There are no Running VM's found, we do not need todo anything" >> $armonitorlog
      echo $ResultPowerOFF >> $armonitorlog
    fi
  fi
else
  if (( DebugLevel > 0 )); then
    echo "Do we need to take action (0 = No / 1 = Yes)? : $takeaction --> No, no action needed!" >> $armonitorlog
  fi
  ## Fill a string to see if there are running Vm's
  #
  RunningVMs=$(VBoxManage list runningvms)
  if (( DebugLevel > 0 )); then
    echo "Found the following machijnes running: $RunningVMs">> $armonitorlog
  fi
fi
