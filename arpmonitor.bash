#!/usr/local/bin/bash

while getopts i:e:c:u:m:l:v:d:p:f:t:g:o:h:r: flag
do
    case "${flag}" in
        i) initialarp=${OPTARG};;
        e) initialdedup=${OPTARG};;
        c) chkarp=${OPTARG};;
        u) chkdeduparp=${OPTARG};;
        m) arpmonitorlog=${OPTARG};;
        l) LANinterface=${OPTARG};;
        v) Interval=${OPTARG};;
        d) DebugLevel=${OPTARG};;
        p) minpercentage=${OPTARG};;
        f) macdifferent=${OPTARG};;
        t) macdiffpercent=${OPTARG};;
        g) gracefultime=${OPTARG};;
        o) maxloops=${OPTARG};;
        h) homedir=${OPTARG};;
        r) iprange=${OPTARG};;
    esac
done

## Debugging
#
#echo "Initialarp: $initialarp";
#echo "Aprmonitorlog: ${arpmonitorlog}";
#echo "IPRange: $iprange";

#exit;

## Colors for echo output
#
# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
LightRed='\033[1;31m'     # Light Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
DarkGray='\033[1;30m'     # Dark Gray

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
#
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

parametererror=""
parameterwarning=""
parameterTIP=""
## If we want to use the homedir, we can insert a lot of parameters at once
#

## Convert Homedir to uppercase
#
homedir="${homedir^^}"

if [ "$homedir" = "Y" ] || [ "$homedir" = "YES" ] || [ "$homedir" = "JA" ] || [ "$homedir" = "1" ]; then
  gebruiker=$(logname)
  initialarp="/home/"
  initialarp+=$gebruiker
  initialarp+="/Data/initialarp.dat"

  initialdedup="/home/"
  initialdedup+=$gebruiker
  initialdedup+="/Data/initialarpdedup.dat"

  chkarp="/home/"
  chkarp+=$gebruiker
  chkarp+="/Data/arpscanning.dat"

  chkdeduparp="/home/"
  chkdeduparp+=$gebruiker
  chkdeduparp+="/Data/arpdedupscanning.dat"

  ${arpmonitorlog}="/home/"
  ${arpmonitorlog}+=$gebruiker
  ${arpmonitorlog}+="/Log/arpmonitor.log"
else
  ## Define Initial ARP result file
  #
  if [ "$initialarp" = "" ]; then
    parametererror+="[Error] initialarp (-i) is not filled in, This is needed for a location for the file of the initialarp scan.%%break%%"
  fi
  if [ "$initialdedup" = "" ]; then
    parametererror+="[Error] initialdedup (-e) is not filled in, This is needed to place the file with unique entry's by arp-scan.%%break%%"
  fi
  if [ "$chkarp" = "" ]; then
    parametererror+="[Error]chkarp (-c) is not filled in, This is needed to place the interval arp-scans file.%%break%%"
  fi
  if [ "$chkdeduparp" = "" ]; then
    parametererror+="[Error]chkdeduparp (-u) is not filled in, This is needed to place the interval arp-scans file.%%break%%"
  fi
  echo "Aprmonitorlog: ${arpmonitorlog}";
  if [ "${arpmonitorlog}" = "" ]; then
    parametererror+="[Error]${arpmonitorlog} (-m) is not filled in, This is needed to place the interval arp-scans file.%%break%%"
  fi
  if [ "$parametererror" = "" ]; then
    parameterTIP+="If you are running this script under a particular user, you can use homedir (-h yes) to let the file location fill in automaticl.%%break%%"
  fi
fi
if [ "$LANinterface" = "" ]; then
  parametererror+="[Error]LANinterface i(-l) is empty, Please specify the Lan interface you wnat to use for the arp-scan.%%break%%"
fi

## Debug level
## 0 = None / 1 = Basic / 2 = Averige / 3 = A lot (Keep those MBs coming!)
#
echo "Debuglevel: ${DebugLevel}";
if ! [[ "$DebugLevel" =~ ^[0-9]+$ ]]; then
  parameterwarning+="DebugLevel (-d) can only contain number (0:None,1:Basic,2: Some More, 3:Extensive) - This parameter gives you control on how much logging must be done. Assuming default logging: .%%break%%"
  DebugLevel=1
elif (( DebugLevel > 3 )); then
  echo "[Warning]DebugLevel (-d) can only contain number (0:None,1:Basic,2: Some More, 3:Extensive) - This parameter gives you control on how much logging must be done. Assuming highest logging: .%%break%%"
  DebugLevel=3
fi

## How long do we sleep before doing the next check (in seconds)
## 3600 = 1 hour / 7200 = 2 hours
#
if ! [[ "$Interval" =~ ^[0-9]+$ ]]; then
  parameterwarning+="[Warning]Interval (-v) can only contain numbers. Here you can specify how long the loop must wait before doing another arp scan. Assuming default: 7200 seconds (2 Hours.%%break%%"
  Interval=7200
  if (( DebugLevel > 0 )); then
    echo "[Warning] Interval (-v) can only contain numbers. Here you can specify how long the loop must wait before doing another arp scan. Assuming default: 7200 seconds (2 Hours)" >> "${arpmonitorlog}"
  fi
elif (( Interval < 300 )); then
  parameterwarning+="[Warning]Interval (-v) has a minimum of 300 seconds waiting time (5 minutes), Assuming the minimal value: 300 seconds.%%break%%"
  Interval=300
  if (( DebugLevel > 0 )); then
    echo "[Warning]Interval (-v) has a minimum of 300 seconds waiting time (5 minutes), Assuming the minimal value: 300 seconds." >> "${arpmonitorlog}"
  fi
fi

## What is the percentage that should be reachable on IP adresses?
#
if ! [[ "$minpercentage" =~ ^[0-9]+$ ]]; then
  parameterwarning+="minpercentage (-p) can only contain numbers between 1 and 100 (%percent%). This parameter gives you control when there is a too low percentage of IP adresses and Mac adresses changed. Assuming standard 70.%%break%%"
  if (( DebugLevel > 0 )); then
    echo "[Warning]minpercentage (-p) can only contain numbers between 1 and 100 (%percent%). This parameter gives you control when there is a too low percentage of IP adresses and Mac adresses changed. Assuming standard 70%" >> "${arpmonitorlog}"
  fi
  minpercentage=70
elif (( minpercentage > 0 )) || (( minpercentage < 101 )); then
  parameterwarning+="minpercentage (-p) out of bounce! It can only contain numbers between 1 and 100 (%percent%). This parameter gives you control when there is a too low percentage of IP adresses and Mac adresses changed. Assuming standard 70.%%break%%"
  if (( DebugLevel > 0 )); then
    echo "[Warning]minpercentage (-p) can only contain numbers between 1 and 100 (%percent%). This parameter gives you control when there is a too low percentage of IP adresses and Mac adresses changed. Assuming standard 70%" >> "${arpmonitorlog}"
  fi
  minpercentage=70
fi

## Can Mac adresses be different? (0=No / 1 = Yes)
#
macdifferent="${macdifferent^^}"

if [ "$macdifferent" = "Y" ] || [ "$macdifferent" = "YES" ] || [ "$macdifferent" = "JA" ] || [ "$macdifferent" = "1" ]; then
  if (( DebugLevel > 0 )); then
    echo "[Warning]User is ok with some Mac adresses to be different (-f). macdifferent=1 --> User also has to define percentage" >> "${arpmonitorlog}"
  fi
  macdifferent=1
  parameterwarning+="User is ok with some Mac adresses to be different (-f). Also define the percentag.%%break%%"
else
  if (( DebugLevel > 0 )); then
    echo "[Warning]No input or invalid input for macdifferent, assuming No (0) zero." >> ${arpmonitorlog}
  fi
  macdifferent=0
fi

## if yes, how many percent?
#
if (( macdifferent > 0 )); then
  if ! [[ "$macdiffpercent" =~ ^[0-9]+$ ]]; then
    parameterwarning+="macdiffpercent (-t) can only contain numbers between 1 and 100 (percent). With this parameter you can control how many Mac adresses may be different if you have choosen mac different to yes (or 1). asssuming default percentage: 80.%%break%%"
    macdiffpercent=80
    if (( DebugLevel > 0 )); then
      echo "[Warning]macdiffpercent (-t) can only contain numbers between 1 and 100 (percent). With this parameter you can control how many Mac adresses may be different if you have choosen mac different to yes (or 1). asssuming default percentage: 80%" >> ${arpmonitorlog}
    fi
  elif (( macdiffpercent > 0 )) || (( macdiffpercent < 101 )); then
    parameterwarning+="macdiffpercent (-t) can only contain numbers between 1 and 100 (percent). With this parameter you can control how many Mac adresses may be different if you have choosen mac different to yes (or 1). asssuming default percentage: 80.%%break%%"
    macdiffpercent=80
    if (( DebugLevel > 0 )); then
      echo "[Warning]macdiffpercent (-t) can only contain numbers between 1 and 100 (percent). With this parameter you can control how many Mac adresses may be different if you have choosen mac different to yes (or 1). asssuming default percentage: 80%" >> ${arpmonitorlog}
    fi
  fi
else
  if (( DebugLevel > 0 )); then
    echo "macdiffpercent (-t) is not needed since there is a zero tolerance on invalid Mac adresses through parameter (-f)" >> ${arpmonitorlog}
  fi
fi

## How much time do we give for the machine to gracefully Shutdown? (in seconds)
#
if ! [[ "$gracefultime" =~ ^[0-9]+$ ]]; then
  parameterwarning+="gracefultime (-g) can only contain numbers. Here you can specify how long we will wait to give an ulitimate shutdown after the gracefully shutdown, minimum: 120 seconds (2 Minutes), we will asume 600 seconds (10 Minutes.%%break%%"
  gracefultime=600
  if (( DebugLevel > 0 )); then
    echo "[Warning]gracefultime (-g) can only contain numbers. Here you can specify how long we will wait to give an ulitimate shutdown after the gracefully shutdown, minimum: 120 seconds (2 Minutes), we will asume 600 seconds (10 Minutes)" >> ${arpmonitorlog}
  fi
elif (( gracefultime < 120 )); then
  parameterwarning+="gracefultime (-g) has a minimum of 120 seconds waiting time (2 minutes), Assuming the minimal value: 120 seconds.%%break%%"
  gracefultime=120
  if (( DebugLevel > 0 )); then
    echo "[Warning]gracefultime (-g) has a minimum of 120 seconds waiting time (2 minutes), Assuming the minimal value: 120 seconds." >> ${arpmonitorlog}
  fi
fi

## What is the maximum of loops this run may run?
#
if ! [[ "$maxloops" =~ ^[0-9]+$ ]]; then
  parameterwarning+="maxloops (-o) can only contain numbers. Here you can specify how many loops this routine can do before it stops with a maximum of 600 times. Assuming default of 336.%%break%%"
  maxloops=336
#  if (( DebugLevel > 0 )); then
#    echo "maxloops (-o) can only contain numbers. Here you can specify how many loops this routine can do before it stops with a maximum of 600 times. Assuming default of 336."
#  fi
elif (( maxloops > 600 )); then
   parameterwarning+="maxloops (-o) has a maximum of 600 loops, the value is too high, changing it to the maximum of 600.%%break%%"
   maxloops=600
   if (( DebugLevel > 0 )); then
    echo "[Warning]maxloops (-o) has a maximum of 600 loops, the value is too high, changing it to the maximum of 600." >> ${arpmonitorlog}
   fi
fi

## Debugging
#
#echo "IPRange if: $iprange";

if valid_ip $iprange; then
  ## IP address is ok, now strip the last digit
  #
  ## Split the IP adress up into an array by '.'
  #
  IFS='.'
  read -ra IPNR <<< "$iprange"

  ## Debugging
  #
  #echo "IPRange: $iprange";

  for ipcount in "${IPNR[@]}"
  do
    # process "$ipcount"
    if (( DebugLevel > 2 )); then
       echo "Processing ipcount: $ipcount" >> ${arpmonitorlog}
    fi
  done
  if (( ipcount > 3 )) then
    parameterwarning+="Entered IP address correct (-r), we will strip the last digit, so we can loop through the possible numbers.%%break%%"
    if (( DebugLevel > 0 )); then
      echo "Entered IP address correct (-r), we will strip the last digit, so we can loop through the possible numbers." >> "${arpmonitorlog}"
    fi
    $iprange=${IPNR[0]}
    $iprange+="."
    $iprange+=${IPNR[1]}
    $iprange+="."
    $iprange+=${IPNR[2]}
    $iprange+="."
  fi
else
  parameterror+="Invalid IP Address in IPRange (-r). IP adress must be (4 Digits with points as limiters) 1.1.1.0 or 192.168.10.0, please correct the input for the IP Range.%%break%%"
fi

## Check if the needed directory's exists, if not warn the user
#
if [ -d "$initialarp" ]; then
  parametererror+="Directory: $initialarp does NOT exists, please create the directory! option:-.%%break%%"
  if (( DebugLevel > 0 )); then
    echo "[Error]Directory $initialarp does NOT exists, please create the directory! option:-i" >> "${arpmonitorlog}"
  fi
fi
if [ -d "$initialdedup" ]; then
  parametererror+="Directory: $initialdedup does NOT exists, please create the directory! option:-.%%break%%"
  if (( DebugLevel > 0 )); then
    echo "[Error]Directory $initialdedup does NOT exists, please create the directory! option:-d" >> "${arpmonitorlog}"
   fi
fi
if [ -d "$chkarp" ]; then
  parametererror+="Directory: $chkarp does NOT exists, please create the directory! option:-.%%break%%"
  if (( DebugLevel > 0 )); then
    echo "[Error]Directory $chkarp does NOT exists, please create the directory! option:-c" >> "${arpmonitorlog}"
   fi
fi
if [ -d "$chkdeduparp" ]; then
  parametererror+="Directory: $chkdeduparp does NOT exists, please create the directory! option:-.%%break%%"
  if (( DebugLevel > 0 )); then
    echo "[Error]Directory $chkdeduparp does NOT exists, please create the directory! option:-u" >> "${arpmonitorlog}"
   fi
fi
if [ -d "${arpmonitorlog}" ]; then
  parametererror+="Directory: ${arpmonitorlog} does NOT exists, please create the directory! option:-.%%break%%"
  if (( DebugLevel > 0 )); then
    echo "[Error]Directory ${arpmonitorlog} does NOT exists, please create the directory! option:-m" >> "${arpmonitorlog}"
   fi
fi

if [ "$parametererror" != "" ]; then
  echo "-----------------------------------------------------------"
  echo "Parameter Warnings (Script will execute)"
  echo "-----------------------------------------------------------"
  echo $parameterwarning
fi
if [ "$parameterTIP" != "" ]; then
  echo "-----------------------------------------------------------"
  echo "Parameter Tips (Script will execute)"
  echo "-----------------------------------------------------------"
  echo $parameterTIP
fi

if [ "$parametererror" != "" ]; then
  echo "-----------------------------------------------------------"
  echo $parametererror
  echo "-----------------------------------------------------------"
  echo "Parameter errors or parameters missing! Explenation:"
  echo ""
  echo "-h : Homedir       --> This means you will be using the script under a particular user."
  echo "                       The parameters: -i -c -u -e -m will be filled in automaticly with /home/USER/...."
  echo "-----------------------------------------------------------"
  echo "These parameters need to be filled in when (-h) Homedir is not used:"
  echo ""
  echo "-i: Initialarp     --> This is the file location of the initial arp-scan (With directory)."
  echo "-d: Initialdedup   --> This is the file location of the initial arp-scan (With directory)."
  echo "-c: ChkArp         --> This is the file location of the interval checks of arp-scan go (With directory)."
  echo "-e: Chkdeduparp    --> This is the file location of the deduplicated file of the interval checks of arp-scan go (With directory)."
  echo "-m: Arpmonitorlog  --> This is the file location where the log file goes. (With directory)."
  echo "-----------------------------------------------------------"
  echo "These parameters always need to be filled in:"
  echo "-l: LANinterface   --> Name of the lan interface."
  echo "-v: Interval       --> The time the script has to wait before doing another arp-scan in seconds."
  echo "-d: DebugLevel     --> how much logging must be done to the logging file (0/1/2/3)"
  echo "-p: minpercentage  --> Minimal percentage that has too be the same Mac and Ip adress as the initial scan"
  echo "-----------------------------------------------------------"
  echo "-f: macdifferent   --> Must every Mac-adress be the same, or do we handle the check in a percentage?"
  echo "-t: macdiffpercent --> If you have used parameter (-f YES) then you need to fill in a percentage to determine how many mac adresses may be different."
  echo "-----------------------------------------------------------"
  echo "-g: gracefultime   --> How many seconds does a Virtual Machine get to gracefully shutdown before a hard poweroff is given (in seconds)."
  echo "-o: maxloops       --> The maximum loops this script may run."
  echo "-r: IP Range       --> This is the range of IP adresses (192.168.8.xxx) that the app will scan. Please enter ip like: 10.10.10.0"
  exit
fi

## We will contineu the script
#
echo -e "${Cyan} -----------------------------------------------------------"
echo -e "${Cyan} Received following parameters"
echo -e "${Cyan} -----------------------------------------------------------"
echo -e "${Cyan} -i: Initialarp     ${Purple} (file)   ${Cyan}: $initialarp"
echo -e "${Cyan} -d: Initialdedup   ${Purple} (file)   ${Cyan}: $initialdedup"
echo -e "${Cyan} -c: ChkArp         ${Purple} (file)   ${Cyan}: $chkarp"
echo -e "${Cyan} -e: chkdeduparp    ${Purple} (file)   ${Cyan}: $chkdeduparp"
echo -e "${Cyan} -l: LANinterface   ${Purple} (name)   ${Cyan}: $LANinterface"
echo -e "${Cyan} -v: Interval       ${Purple} (number) ${Cyan}: $Interval"
echo -e "${Cyan} -d: DebugLevel     ${Purple} (number) ${Cyan}: $DebugLevel"
echo -e "${Cyan} -p: minpercentage  ${Purple} (number) ${Cyan}: $minpercentage"
echo -e "${Cyan} -----------------------------------------------------------"
echo -e "${Cyan} -f: macdifferent   ${Purple} (bolean) ${Cyan}: $macdifferent"
echo -e "${Cyan} -t: macdiffpercent ${Purple} (number) ${Cyan}: $macdiffpercent"
echo -e "${Cyan} -----------------------------------------------------------"
echo -e "${Cyan} -g: gracefultime   ${Purple} (seconds)${Cyan}: $gracefultime"
echo -e "${Cyan} -o: maxloops       ${Purple} (number) ${Cyan}: $maxloops"
echo -e "${Cyan} -r: IP Range       ${Purple} (number) ${Cyan}: $iprange"

#exit;

if (( DebugLevel > 0 )); then
  echo "Start the Arp Monitor routine, first do a initial arp-scan" >> "${arpmonitorlog}"
fi

SCANiprange="${iprange}/24"

echo "SCan IP Range: $SCANiprange"

## Get the initial Mac adresses of the network (Only Once and save it)
#
arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|' $SCANiprange > "${initialarp}"

if (( DebugLevel > 0 )); then
  echo "Remove the possible double entry;s from the initial ARP Scan" > "${arpmonitorlog}"
fi

## Insert the arp initial file into an array, and break each line with WhiteSpace
#
IFS=$'\n' read -d '' -r -a initiallines < "${initialarp}"

## Remove the double entry's
#
count=0
initialduplicates=0

if (( DebugLevel > 0 )); then
  echo "## Deduplication of initial Arp-scan results" >> "${arpmonitorlog}"
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
    if (( DebugLevel > 2 )); then
      echo "Remember: $remember --> $initialline --> $tellen" >> "${arpmonitorlog}"
    fi

    if [ "$remember" = "$initialline" ]; then
      let found=1
      if (( DebugLevel > 1 )); then
        echo "## Found a duplicate line: $initialline #########################" >> "${arpmonitorlog}"
      fi
    fi
    let tellen=tellen+1
  done
  if (( $found == 0 )) ; then
    ## Save this line it is unique
    #
    echo $initialline >> "${initialdedup}"
  else
    ## Count the duplicates
    #
    initialduplicates=$((initialduplicates + 1))
  fi
  count=$((count + 1))
done
initialcount=$count

let endless=0
while [ $endless -lt $maxloops ]; do
        if (( DebugLevel > 0 )); then
          echo "Loop through each line of initial arp-scan" >> "${arpmonitorlog}"
        fi

        IFS=$'\n' read -d '' -r -a initiallines < "${initialdedup}"

        count=0
        countfilledlines=0

        for initialline in "${initiallines[@]}"
        do
           # do whatever on "$initialline" here
           #echo $initialline
           IFS='|' read -ra INITIALADDR <<< "$initialline"

           if (( DebugLevel > 1 )); then
                 echo "initial IP:  ${INITIALADDR[1]} - count: $count" >> "${arpmonitorlog}"
                 echo "initial Mac: ${INITIALADDR[2]} - count: $count" >> "${arpmonitorlog}"
           fi

           InitialIP[$count]=${INITIALADDR[1]}
           InitialMac[$count]=${INITIALADDR[2]}
           fullempty=${INITIALADDR[1]}

           if [ "$fullempty" != "" ]; then
                  ## Only count the filled lines
                  #
                  countfilledlines=$((countfilledlines + 1))
                  if (( DebugLevel > 0 )); then
                        echo "Filled InitialIP counted: ${InitialIP[$count]} - ${InitialMac[$count]}" >> "${arpmonitorlog}"
                  fi
           fi

           #echo "Initial IP: ${InitialIP[$count]}"
           #echo "Initial Mac: ${InitialMac[$count]}"

           count=$((count + 1))
        done

        ## Sleep before doing checkups
        #
        if (( DebugLevel > 0 )); then
          echo "Sleeping $iNTERVAL BEFORE NEXT INTERVAL CHECK...." >> "${arpmonitorlog}"
        fi
        sleep $Interval

        arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|' 192.30.177.0/24 > "${chkarp}"

        ## Insert the arp file into an array, and break each line with WhiteSpace
        #
        IFS=$'\n' read -d '' -r -a chklines < $chkarp

        ## Remove the double entry's
        #
        count=0
        chkduplicates=0
        echo "## Deduplication of Returning Arp-scan results" > "${chkdeduparp}"
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
                  echo "Remember: $remember --> $initialline --> $tellen"  >> "${arpmonitorlog}"
                fi

                if [ "$remember" = "$chkline" ]; then
                  let found=1
                  if (( DebugLevel > 0 )); then
                        echo "## Found a duplicate line: $chkline #########################" >> "${arpmonitorlog}"
                  fi
                fi
                let tellen=tellen+1
          done
          if (( $found == 0 )) ; then
                ## Save this line it is unique
                #
                echo $chkline >> "${chkdeduparp}"
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
        IFS=$'\n' read -d '' -r -a chklines < "$chkdeduparp"

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
                 echo $chkline >> "${arpmonitorlog}"
           fi

           ## Split the string with delimiter P|pe from string $chkline
           #
           IFS='|' read -ra CHKADDR <<< "$chkline"

           chkIP=${CHKADDR[1]}
           chkMac=${CHKADDR[2]}

           if (( DebugLevel > 2 )); then
                 echo $chkIP >> "${arpmonitorlog}"
                 echo $chkMac >> "${arpmonitorlog}"
           fi

           if [ "$chkIP" != "" ]; then
                 ## Check the IP adresses and Mac adresses with the initial Arp-scan
                 #
                 let tellen=0
                 while [ $tellen -lt $count ]; do
                   ## Little less logging may be done, lets regulated it with a parameter
                   #
                   if (( DebugLevel > 2 )); then
                         echo "Checking IP and Mac against original IP and Mac $tellen (${chkIP} : ${InitialIP[$tellen]} / ${chkMac} : ${InitialMac[$tellen]} " >> "${arpmonitorlog}"
                   fi

                   initIP=${InitialIP[$tellen]}

                   if [ "$chkIP" = "$initIP" ]; then
                         if (( DebugLevel > 0 )); then
                           echo "found $chkIP - $initIP - Checking if Mac adress is correct...." >> "${arpmonitorlog}"
                         fi
                         initMac=${InitialMac[$tellen]}
                         if [ "$chkMac" = "$initMac" ]; then
                           if (( DebugLevel > 1 )); then
                                 echo "Mac adress: $chkMac is the same as: $initMac" >> "${arpmonitorlog}"
                           fi

                           countmacok=$((countmacok + 1))
                         else
                           if (( DebugLevel > 1 )); then
                                 echo "Mac adress: $chkMac is different: $initMac" >> "${arpmonitorlog}"
                           fi
                           countmacfault=$((countmacfault + 1))
                         fi
                         countmactotal=$((countmactotal + 1))
                   fi
                   let tellen=tellen+1
                 done
          fi
        done

        echo "Initial ARP count with duplicates: ${initialcount}"
        echo "CountMac Total: ${countmactotal}"
        echo "CountMac OK: ${countmacok}"
        echo "CountMac Fault: ${countmacfault}"
        echo "Count Filled Lines: ${countfilledlines}"
        echo "Initial Duplicate lines found: ${initialduplicates}"
        echo "Re-accuring Duplicates found: ${chkduplicates}"

        if (( DebugLevel > 0 )); then
          echo "Initial ARP count with duplicates: $initialcount" >> "${arpmonitorlog}"
          echo "CountMac Total: $countmactotal" >> "${arpmonitorlog}"
          echo "CountMac OK: $countmacok" >> "${arpmonitorlog}"
          echo "CountMac Fault: $countmacfault" >> "${arpmonitorlog}"
          echo "Count Filled Lines: $countfilledlines" >> "${arpmonitorlog}"
          echo "Initial Duplicate lines found: $initialduplicates" >> "${arpmonitorlog}"
          echo "Re-accuring Duplicates found: $chkduplicates" >> "${arpmonitorlog}"
        fi

        howmanyprocent=$((100*$countmacok/$countfilledlines))
        echo "How many percent is missing from the initial arp-scan: ${howmanyprocent}"
        if (( DebugLevel > 0 )); then
          echo "How many percent is missing from the initial arp-scan: ${howmanyprocent}" >> "${arpmonitorlog}"
        fi

        ## Check if the percentage is less than the minimum percentage, if it is less take action.
        #
        let takeaction=0
        if [ $howmanyprocent -lt $minpercentage ]; then
          ## Less than the minimal percentage is there, take action!
          if (( DebugLevel > 0 )); then
                echo "The found ip adres percentage: $howmanyprocent is lower than $minpercentage, take action!" >> "${arpmonitorlog}"
          fi

          let takeaction=1
        else
          ## Within percentage, all is ok!
          if (( DebugLevel > 0 )); then
                echo "The found ip adres percentage: $howmanyprocent is higher than $minpercentage, all is well!" >> "${arpmonitorlog}"
          fi
          takeaction=0
        fi

        ## Check if an mac adress may change
        #
        if [ $macdifferent -eq 0 ]; then
          ## All mac adresses must be the same on the same ip adressses
          if (( DebugLevel > 0 )); then
                echo "All Mac adresses MUST be the same, check if there are faulty MAc adresses" >> "${arpmonitorlog}"
          fi

          if [ $countmacfault -gt 0 ]; then
                ## There is a problem, an mac adress is different
                if (( DebugLevel > 0 )); then
                  echo "Number of faulty mac adresses: $countmacfault, None is the Rule, take action!" >> "${arpmonitorlog}"
                fi

                let takeaction=1
          else
                if (( DebugLevel > 0 )); then
                  echo "All Mac adresses are the same as the initial readout by arp-scan" >> "${arpmonitorlog}"
                fi
          fi
        else
          ## Yes there may be a difference, but how many percent?
          ## $macdiffpercent
          #
          if (( DebugLevel > 0 )); then
                echo "Not all Mac adresses in the network have to be exactly the same, a minimal percentage is given: $diffprocent" >> "${arpmonitorlog}"
          fi

          diffprocent=$((100*$countmacok/$countmactotal))
          if [ $diffprocent -lt $macdiffpercent]; then
                ## Less than the minimal percentage is there, take action!
                if (( DebugLevel > 0 )); then
                  echo "The Mac pass percentage: $macdiffpercent is lower than $diffprocent, take action!" >> "${arpmonitorlog}"
                fi
                let takeaction=1
          else
                ## Within percentage, all is ok!
                if (( DebugLevel > 0 )); then
                  echo "The Mac pass percentage: $howmanyprocent is higher than $minpercentage, all is well!" >> "${arpmonitorlog}"
                fi

                let takeaction=0
          fi
        fi

        echo "Do we need to take action (0 = No / 1 = Yes)? : $takeaction"
        if (( takeaction > 0 )); then
          if (( DebugLevel > 0 )); then
                echo "Do we need to take action (0 = No / 1 = Yes)? : $takeaction --> Yes! we need to take action!" >> "${arpmonitorlog}"
          fi

          ## Fill a string to see if there are running Vm's
          #
          RunningVMs=$(VBoxManage list runningvms)
          if (( DebugLevel > 0 )); then
                echo "Found the following machijnes running: $RunningVMs" >> "${arpmonitorlog}"
          fi
          if [ "$RunningVMs" != "" ]; then
                ## Yes the VM for this user is running, make it shutdown gracefully
                #
                ## First get the machine name the smart way (From the string), we need to split the string on a [space]
                #
                IFS=' ' read -ra VMNAME <<< "$RunningVMs"
                VboxName=${VMNAME[0]}
                VboxName="${VboxName//\"}"

                if (( DebugLevel > 1 )); then
                  echo "Virtual Machine name found: $VboxName"
                fi
                ## First get the machine name the smart way (From the string)
                #
                if (( DebugLevel > 1 )); then
                  echo "Pressing ACPI Powerbutton for Virtual Machine:  $VboxName to gracefully shutdown the machine" >> "${arpmonitorlog}"
                fi
                ResultPWRButton=$(VBoxManage controlvm $VboxName acpipowerbutton)

                if (( DebugLevel > 1 )); then
                  echo "Give time for the Virtual Machine:  $VboxName to gracefully shutdown, sleep for $gracefultime seconds" >> "${arpmonitorlog}"
                  echo $ResultPWRButton >> "${arpmonitorlog}"
                fi
                sleep $gracefultime

                if (( DebugLevel > 1 )); then
                  echo "To be fully sure, poweroff the VM : ${VboxName}" >> "${arpmonitorlog}"
                fi
                ResultPowerOFF=$(VBoxManage controlvm $VboxName poweroff)

                ## Stop the endless routine for this machine, it does not run anymore
                #
                let endless=endless+1000
                if (( DebugLevel > 1 )); then
                  echo "VM has been shut down" >> "${arpmonitorlog}"
                  echo $ResultPowerOFF >> "${arpmonitorlog}"
                fi
          else
                if (( DebugLevel > 0 )); then
                  echo "There are no Running VM's found, we do not need todo anything" >> "${arpmonitorlog}"
                fi
          fi
        else
          if (( DebugLevel > 0 )); then
                echo "Do we need to take action (0 = No / 1 = Yes)? : $takeaction --> No, no action needed!" >> "${arpmonitorlog}"
          fi
          ## Fill a string to see if there are running Vm's
          #
          RunningVMs=$(VBoxManage list runningvms)
          if (( DebugLevel > 0 )); then
                echo "Found the following machijnes running: $RunningVMs">> "${arpmonitorlog}"
          fi
        fi
  let endless=endless+1
done
