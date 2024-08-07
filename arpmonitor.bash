#!/usr/local/bin/bash

arpmonitorlog="arp_error.log"

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

## Colors for echo output
#
declare -A kleur

# Reset
kleur[Color_Off]='\033[0m'       # Text Reset

# Regular Colors
kleur[Black]='\033[0;30m'        # Black
kleur[Red]='\033[0;31m'          # Red
kleur[LightRed]='\033[1;31m'     # Light Red
kleur[Green]='\033[0;32m'        # Green
kleur[Yellow]='\033[0;33m'       # Yellow
kleur[Blue]='\033[0;34m'         # Blue
kleur[Purple]='\033[0;35m'       # Purple
kleur[Cyan]='\033[0;36m'         # Cyan
kleur[White]='\033[0;37m'        # White
kleur[DarkGray]='\033[1;30m'     # Dark Gray

# Background
kleur[OnBlack]='\033[40m'       # Black
kleur[OnRed]='\033[41m'         # Red
kleur[OnGreen]='\033[42m'       # Green
kleur[OnYellow]='\033[43m'      # Yellow
kleur[OnBlue]='\033[44m'        # Blue
kleur[OnPurple]='\033[45m'      # Purple
kleur[OnCyan]='\033[46m'        # Cyan
kleur[OnWhite]='\033[47m'       # White

## What do we use to break the line in a big BIG $tring?
#
breken="%%break%%"

## Function to write log files
#
function WriteLog()
  {
     ## Fucntion to write to log files, First Get the date
     ## Put it into a $string
     ##
     ## $1 = Write to log? (1=yes/0=no)
     ## $2 = Message to Write (and/or Print)
     ## $3 = Write to screen (1=yes/0=no)
     ## $4 = Color? (Empty = No / Filled = Color)
     #
     funcDATUMTijd=$(date +%A-%d-%B-%Y--%T)
     FUNCMessage="${funcDATUMTijd}"
     FUNCMessage+=" --> "

     if (( DebugLevel > 4 )); then
         echo "WriteLog Function called!"
         echo $1
         echo $2
         echo $3
         echo $4
     fi

     ## $5 <> "" Then print [Error] [Warning] or [Info]
     ## in front of the log entry
     #
     if [ -n "$5" ]; then
       if [ "$5" = "[E]" ]; then
         prefix="[Error]"
       elif [ "$5" = "[W]" ]; then
         prefix="[Warning]"
       elif [ "$5" = "[I]" ]; then
         prefix="[Info]"
       else
         prefix=""
       fi
     else
       prefix=""
     fi

     ## Get Date Time of this moment in THIS Function
     #
     funcDATUMTijd=$(date +%A-%d-%B-%Y--%T)

     ## Fill the message with value 2 from function
     #
     FUNCMessage=$2
     LOGmsg=${funcDATUMTijd}
     LOGmsg+=" --> "
     LOGmsg+=$prefix
     LOGmsg+=" "
     LOGmsg+=$FUNCMessage

     ## $1 > 0 then Write String $2 to log file
     #
     if (( $1 > 0 )); then
          ## Add an entry to the log file
          #
          echo $LOGmsg >> "${arpmonitorlog}"
     fi

     ## If $3 Greater than 0 then print to COnsole (Write-Host)
     #
     if (($3 > 0)); then
         if [ "$4" = "" ]; then
              ## Color is EMPTY, so NOT defined, use standard color
              ##
              ## echo $FUNCMessage
              #
              echo -e "${kleur[Color_Off]}${FUNCMessage}"
         else
              ## Print text in color to screen
              #
              echo -e "${kleur[$4]}${FUNCMessage}"
         fi
     fi
  }

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
    whatmsg="initialarp (-i) is not filled in, This is needed for a location for the file of the initialarp scan."
    parametererror+=$whatmsg
    parametererror+=$breken
    WriteLog 1 "$whatmsg" 0 Red [E]
  fi
  if [ "$initialdedup" = "" ]; then
    whatmsg="[Error] initialdedup (-e) is not filled in, This is needed to place the file with unique entry's by arp-scan."
    parametererror+=$whatmsg
    parametererror+=$breken
    WriteLog 1 "$whatmsg" 0 Red
  fi
  if [ "$chkarp" = "" ]; then
    whatmsg="[Error]chkarp (-c) is not filled in, This is needed to place the interval arp-scans file."
    parametererror+=$whatmsg
    parametererror+=$breken
    WriteLog 1 "$whatmsg" 0 Red
  fi
  if [ "$chkdeduparp" = "" ]; then
    whatmsg="[Error]chkdeduparp (-u) is not filled in, This is needed to place the interval arp-scans file."
    parametererror+=$whatmsg
    parametererror+=$breken
    WriteLog 1 "$whatmsg" 0 Red
  fi
  echo "Aprmonitorlog: ${arpmonitorlog}";
  if [ "${arpmonitorlog}" = "" ]; then
    whatmsg="[Error]${arpmonitorlog} (-m) is not filled in, This is needed to place the interval arp-scans file."
    parametererror+=$whatmsg
    parametererror+=$breken
    WriteLog 1 "$whatmsg" 0 Red
  fi
  if [ "$parametererror" = "" ]; then
    whatmsg="If you are running this script under a particular user, you can use homedir (-h yes) to let the file location fill in automaticl."
    parameterTIP+=$whatmsg
    parameterTIP+=$breken
    WriteLog 1 "$whatmsg" 0 Red
  fi
fi
if [ "$LANinterface" = "" ]; then
  whatmsg="[Error]LANinterface i(-l) is empty, Please specify the Lan interface you wnat to use for the arp-scan."
  parametererror+=$whatmsg
  parametererror+=$breken
  WriteLog 1 "$whatmsg" 0 Red
fi

## Debug level
## 0 = None / 1 = Basic / 2 = Averige / 3 = A lot (Keep those MBs coming!)
#
echo "Debuglevel: ${DebugLevel}";
if ! [[ "$DebugLevel" =~ ^[0-9]+$ ]]; then
  whatmsg="DebugLevel (-d) can only contain number (0:None,1:Basic,2: More, 3:Some more, 4:Extensive, 5:MegaBytes Extensive) - This parameter gives you control on how much logging must be done. Assuming default logging: 3"
  parameterwarning+=$whatmsg
  parameterwarning+=$breken

  WriteLog 1 "$whatmsg" 0 Yellow
  DebugLevel=1
elif (( DebugLevel > 5 )); then
  ## Write to the log file
  #
  whatmsg="DebugLevel (-d) is too high (0:None,1:Basic,2: More, 3:Some more, 4:Extensive, 5:MegaBytes Extensive) - Assuming default logging: 3"
  WriteLog 1 "$whatmsg" 0 Yellow
  DebugLevel=3
fi

## How long do we sleep before doing the next check (in seconds)
## 3600 = 1 hour / 7200 = 2 hours
#
if ! [[ "$Interval" =~ ^[0-9]+$ ]]; then
  whatmsg="[Warning] Interval (-v) can only contain numbers. Here you can specify how long the loop must wait before doing another arp scan. Assuming default: 7200 seconds (2 Hours)"
  parameterwarning+=$whatmsg
  parameterwarning+=$breken

  #WriteLog 1 "$whatmsg" 0 Red
  Interval=7200
  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Yellow
  fi
elif (( Interval < 300 )); then
  whatmsg="[Warning]Interval (-v) has a minimum of 300 seconds waiting time (5 minutes), Assuming the minimal value: 300 seconds."
  parameterwarning+=$whatmsg
  parameterwarning+=$breken
  Interval=300
  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Yellow
  fi
fi

## What is the percentage that should be reachable on IP adresses?
#
if ! [[ "$minpercentage" =~ ^[0-9]+$ ]]; then
  whatmsg="minpercentage (-p) can only contain numbers between 1 and 100 (%percent%). This parameter gives you control when there is a too low percentage of IP adresses and Mac adresses changed. Assuming standard 70.%%break%%"
  parameterwarning+=$whatmsg
  parameterwarning+=$breken

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Yellow
  fi
  minpercentage=70
elif (( minpercentage > 0 )) || (( minpercentage < 101 )); then
  whatmsg="minpercentage (-p) out of bounce! It can only contain numbers between 1 and 100 (%percent%). This parameter gives you control when there is a too low percentage of IP adresses and Mac adresses changed. Assuming standard 70."
  parameterwarning+=$whatmsg
  parameterwarning+=$breken

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Yellow
  fi
  minpercentage=70
fi

## Can Mac adresses be different? (0=No / 1 = Yes)
#
macdifferent="${macdifferent^^}"

if [ "$macdifferent" = "Y" ] || [ "$macdifferent" = "YES" ] || [ "$macdifferent" = "JA" ] || [ "$macdifferent" = "1" ]; then
  whatmsg="User is ok with some Mac adresses to be different (-f). macdifferent=1 --> User also has to define percentage"
  parameterwarning+=$whatmsg
  parameterwarning+=$breken
  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Yellow
  fi
  macdifferent=1
else
  whatmsg="No input or invalid input for macdifferent, assuming No (0) zero."
  parameterwarning+=$whatmsg
  parameterwarning+=$breken
  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Yellow
  fi
  macdifferent=0
fi

## if yes, how many percent?
#
if (( macdifferent > 0 )); then
  if ! [[ "$macdiffpercent" =~ ^[0-9]+$ ]]; then
    whatmsg="macdiffpercent (-t) can only contain numbers between 1 and 100 (percent). With this parameter you can control how many Mac adresses may be different if you have choosen mac different to yes (or 1). asssuming default percentage: 80."
    parameterwarning+=$whatmsg
    parameterwarning+=$breken
    macdiffpercent=80

    if (( DebugLevel > 0 )); then
      WriteLog 1 "$whatmsg" 0 Yellow
    fi
  elif (( macdiffpercent > 0 )) || (( macdiffpercent < 101 )); then
    whatmsg="macdiffpercent (-t) can only contain numbers between 1 and 100 (percent)(%). With this parameter you can control how many Mac adresses may be different if you have choosen mac different to yes (or 1). asssuming default percentage: 80.%%break%%"
    parameterwarning+=$whatmsg
    parameterwarning+=$breken
    macdiffpercent=80

    if (( DebugLevel > 0 )); then
      WriteLog 1 "$whatmsg" 0 Yellow
    fi
  fi
else
  if (( DebugLevel > 0 )); then
    whatmsg="macdiffpercent (-t) is not needed since there is a zero tolerance on invalid Mac adresses through parameter (-f)"
    WriteLog 1 "$whatmsg" 0 Green
  fi
fi

## How much time do we give for the machine to gracefully Shutdown? (in seconds)
#
if ! [[ "$gracefultime" =~ ^[0-9]+$ ]]; then
  whatmsg="gracefultime (-g) can only contain numbers. Here you can specify how long we will wait to give an ulitimate shutdown after the gracefully shutdown, minimum: 120 seconds (2 Minutes), we will asume 600 seconds (10 Minutes)"
  parameterwarning+=$whatmsg
  parameterwarning+=$breken
  gracefultime=600

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Yellow
  fi
elif (( gracefultime < 120 )); then
  whatmsg="gracefultime (-g) has a minimum of 120 seconds waiting time (2 minutes), Assuming the minimal value: 120 seconds."
  parameterwarning+=$whatmsg
  parameterwarning+=$breken
  gracefultime=120

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Yellow
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
echo -e "${kleur[Cyan]} -----------------------------------------------------------"
echo -e "${kleur[Cyan]} Received following parameters"
echo -e "${kleur[Cyan]} -----------------------------------------------------------"
echo -e "${kleur[Cyan]} -i: Initialarp     ${kleur[Purple]} (file)   ${kleur[Cyan]}: $initialarp"
echo -e "${kleur[Cyan]} -d: Initialdedup   ${kleur[Purple]} (file)   ${kleur[Cyan]}: $initialdedup"
echo -e "${kleur[Cyan]} -c: ChkArp         ${kleur[Purple]} (file)   ${kleur[Cyan]}: $chkarp"
echo -e "${kleur[Cyan]} -e: chkdeduparp    ${kleur[Purple]} (file)   ${kleur[Cyan]}: $chkdeduparp"
echo -e "${kleur[Cyan]} -l: LANinterface   ${kleur[Purple]} (name)   ${kleur[Cyan]}: $LANinterface"
echo -e "${kleur[Cyan]} -v: Interval       ${kleur[Purple]} (seconds)${kleur[Cyan]}: $Interval"
echo -e "${kleur[Cyan]} -d: DebugLevel     ${kleur[Purple]} (number) ${kleur[Cyan]}: $DebugLevel"
echo -e "${kleur[Cyan]} -p: minpercentage  ${kleur[Purple]} (number) ${kleur[Cyan]}: $minpercentage"
echo -e "${kleur[Cyan]} -----------------------------------------------------------"
echo -e "${kleur[Cyan]} -f: macdifferent   ${kleur[Purple]} (bolean) ${kleur[Cyan]}: $macdifferent"
echo -e "${kleur[Cyan]} -t: macdiffpercent ${kleur[Purple]} (number) ${kleur[Cyan]}: $macdiffpercent"
echo -e "${kleur[Cyan]} -----------------------------------------------------------"
echo -e "${kleur[Cyan]} -g: gracefultime   ${kleur[Purple]} (seconds)${kleur[Cyan]}: $gracefultime"
echo -e "${kleur[Cyan]} -o: maxloops       ${kleur[Purple]} (number) ${kleur[Cyan]}: $maxloops"
echo -e "${kleur[Cyan]} -r: IP Range       ${kleur[Purple]} (number) ${kleur[Cyan]}: $iprange"

#exit;

if (( DebugLevel > 0 )); then
  echo "Start the Arp Monitor routine, first do a initial arp-scan" >> "${arpmonitorlog}"
fi

SCANiprange="${iprange}/24"

echo "Scan IP Range: $SCANiprange"

## Get the initial Mac adresses of the network (Only Once and save it)
#
arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|' "${SCANiprange}" > "${initialarp}"

if (( DebugLevel > 0 )); then
  echo "Remove the possible double entry;s from the initial ARP Scan" > "${arpmonitorlog}"
fi

## Insert the arp initial file into an array, and break each line with WhiteSpace
#
IFS=$'\n' read -d '' -r -a initiallines < "$initialarp"

## Remove the double entry's
#
count=0
initialduplicates=0

if (( DebugLevel > 0 )); then
  echo "## Deduplication of initial Arp-scan results" >> "${arpmonitorlog}"
fi

## Start a new initial De-Duplication File
#
DATUMTijd=$(date +%A-%d-%B-%Y--%T)
STARTMessage="Start Date & Time of initial deduplication: "
STARTMessage+="${DATUMTijd}"
echo ${STARTMessage} > "${initialdedup}"

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
    if (( DebugLevel > 2 )); then
      echo "Add line to dedup file it is unique: ${initialline}" >> "${arpmonitorlog}"
    fi
  else
    ## Count the duplicates
    #
    initialduplicates=$((initialduplicates + 1))
    if (( DebugLevel > 2 )); then
      echo "Count the duplicates: ${initialduplicates}" >> "${arpmonitorlog}"
    fi
  fi
  count=$((count + 1))
done
initialcount=$count

let endless=0
while [ $endless -lt $maxloops ]; do
        if (( DebugLevel > 0 )); then
          echo "Loop through each line of initial arp-scan" >> "${arpmonitorlog}"
        fi

        IFS=$'\n' read -d '' -r -a initiallines < "$initialdedup"

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

        arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|' "${SCANiprange}" > "${chkarp}"

        ## Insert the arp file into an array, and break each line with WhiteSpace
        #
        IFS=$'\n' read -d '' -r -a chklines < "$chkarp"

        ## Remove the double entry's
        #
        count=0
        chkduplicates=0
        echo "## Deduplication of Returning Arp-scan results" >> "${arpmonitorlog}"

        ## Write the first line of the interval deduplication file
        #
        DATUMTijd=$(date +%A-%d-%B-%Y--%T)
        STARTMessage="Start Date & Time of Check interval deduplication: "
        STARTMessage+="${DATUMTijd}"
        echo ${STARTMessage} > "${chkdeduparp}"

        for chkline in "${chklines[@]}"
        do
          chkdedup[$count]=$chkline

          let tellen=0
          let found=0
          #remember=""
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

        if (( $countfilledlines < 0 )); then
          howmanyprocent=$((100*$countmacok/$countfilledlines))
        else
          howmanyprocent=0
        fi
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
          if [ $diffprocent -lt $macdiffpercent ]; then
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
