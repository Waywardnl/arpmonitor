#!/usr/local/bin/bash

## You need to install the following package to execute this file succesfully
##
## pkg install arp-scan
## pkg install ipcalc

while getopts i:e:c:u:m:l:v:d:p:f:t:g:o:h:r:s:x:n: flag
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
        s) ipsubnet=${OPTARG};;
        x) logmaxsize=${OPTARG};;
        n) numberinstances=${OPTARG};;
    esac
done

#echo "Number of instances: $numberinstances"

## Debugging
#
#echo "Initialarp: $initialarp";
#echo "Aprmonitorlog: ${arpmonitorlog}";
#echo "IPRange: $iprange";

#exit;

## Fallback log
#
fallbackarpmonitorlog="arp_fallback.log"

## Minimal bytes for maximal log file size when debigging is higher than 2
## If it is to low, the script will only rotate the log file
#
minlogmaxsizehighdebug=100000

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
kleur[LightYellow]='\033[1;33m'  # Light Yellow
kleur[Yellow]='\033[0;33m'       # Yellow
kleur[Blue]='\033[0;34m'         # Blue
kleur[LightBlue]='\033[1;34m'    # Light Blue
kleur[Purple]='\033[0;35m'       # Purple
kleur[Cyan]='\033[0;36m'         # Cyan
kleur[LightGray]='\033[0;37m'    # Light Gray
kleur[White]='\033[1;37m'        # White
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
breken="|"

## Please take the standard divider into a string
#
divider="-----------------------------------------------------------"

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
     ##
     #####################################################
     ## You may NOT call WriteLog() Function from within
     ## this function! (Or you will create a loop)
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
       if [ "$5" = "E" ]; then
         prefix="[Error]"
       elif [ "$5" = "W" ]; then
         prefix="[Warning]"
       elif [ "$5" = "I" ]; then
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
     tarDATUMTijd=$(date +%A-%d-%B-%Y--%H-%M-%S)

     ## Fill the message with value 2 from function
     #
     FUNCMessage=$2
     LOGmsg=${funcDATUMTijd}
     LOGmsg+=" --> "
     LOGmsg+=$prefix
     LOGmsg+=" "
     LOGmsg+=$FUNCMessage

     ## Write to the log after it is checked if the log file exists or NOT
     #
     #echo $LOGmsg >> "${arpmonitorlog}"

     ## $1 > 0 then Write String $2 to log file
     #
     prnlog=$1

     ## $1 > 0 then Write String $2 to log file
     #
     #if (( $1 > 0 )); then
     if (( $prnlog > 0 )); then
          ## Add an entry to the log file
          #
          if [ -n "$arpmonitorlog" ]; then
            ## Check if the file exists
            #
            if [ -f "$arpmonitorlog" ]; then
              ## Go on with script file
              #
              writetolog=1
              echo $LOGmsg >> "${arpmonitorlog}"

              if (( DebugLevel > 4 )); then
                 ## Write to the log file
                 #
                 internmsg="Log file: $arpmonitorlog exists, write to the log file!"
                 echo  $internmsg >> "${arpmonitorlog}"
               fi

            else
              echo "Log file: $arpmonitorlog does not exist, write a new log file (and a new entry)" > "${arpmonitorlog}"
            fi

            ## Write the new entry to the log file
            ##
            ## But Lets check the size of the log file first
            ##
            #file=file.txt
            actualsize=$(wc -c <"$arpmonitorlog")

            if [ $actualsize -gt $logmaxsize ]; then
              if (( DebugLevel > 0 )); then
                echo "size is over $logmaxsize bytes" >> "${arpmonitorlog}"
              fi

              ziptar=$(echo "$arpmonitorlog" | sed "s/\.log/\(log)_$tarDATUMTijd.tar/g")

              tar --verbose -czf "$ziptar" "$arpmonitorlog"

              ## Overwrite log file with new entry
              #
              LOGmsg=${funcDATUMTijd}
              LOGmsg+=" --> "
              LOGmsg+=$prefix
              LOGmsg+=" "
              LOGmsg+="Log file rotated and tarred deu to size of Log file exceeded: $logmaxsize bytes."
              echo $LOGmsg > "${arpmonitorlog}"
            else
              ## We want to leave 5 tar files and remove the older ones
              #
              ## Get the path without the filename
              ##
              ## https://stackoverflow.com/questions/125281/how-do-i-remove-the-file-suffix-and-path-portion-from-a-path-string-in-bash
              ## https://mywiki.wooledge.org/BashFAQ/003
              #
              rotatedir=$(dirname "${arpmonitorlog}")
              #rotatedir+="/"

              if (( DebugLevel > 4 )); then
                 ## Write to the log file
                 #
                 internmsg="Rotate Directory --> $rotatedir"
                 echo $internmsg
               fi

              if (( DebugLevel > 2 )); then
                internmsg="Rotate Directory --> $rotatedir"
                echo $internmsg >> "${arpmonitorlog}"
              fi

              #echo ". $rotatedir ."

              ## Count number of *.tar Files
              #
              teltarfiles=$(find "$rotatedir" -type f -iname "*.tar" | wc -l)
              if (( teltarfiles > 5 )); then
                ## Show howmany Tar files have been found
                #
                if (( DebugLevel > 4 )); then
                  ## Write to the log file
                  #
                  echo "We counted: $teltarfiles TAR Files, Run the tar file cleanup routine!" >> "${arpmonitorlog}"
                fi

                ## https://mywiki.wooledge.org/BashFAQ/003
                #
                unset -v oldest
                for file in "$rotatedir"/*.tar; do
                  [[ -z $oldest || $file -ot $oldest ]] && oldest=$file

                  if (( DebugLevel > 2 )); then
                    ## Write to the log file
                    #
                    echo "Rotate Log --> Handling: $file"  >> "${arpmonitorlog}"
                  fi
                  if (( DebugLevel > 4 )); then
                    ## Write to the log file
                    #
                    echo "Rotate Log --> Handling: $file" >> "${arpmonitorlog}"
                  fi

                done

                if (( DebugLevel > 4 )); then
                  ## Write to the log file
                  #
                  whatmsg="Deleting Oldest (Log) TAR File: $oldest"
                  echo $whatmsg
                fi
                if (( DebugLevel > 2 )); then
                  ## Write to the log file
                  #
                  whatmsg="Deleting Oldest (Log) TAR File: $oldest"
                  echo $whatmsg  >> "${arpmonitorlog}"
                fi
                if (( DebugLevel > 1 )); then
                  echo "Removed: $oldest" >> "${arpmonitorlog}"
                fi
                rm "$oldest"
                echo "Removed: $oldest"
              fi
            fi
          else
            ## Arp monitor log file is empty, using fallback log
            #
            fallbackmsg="${kleur[Red]}Monitor log is not filled, using fallback log file: "
            fallbackmsg+="${kleur[Cyan]}${fallbackarpmonitorlog}"
            fallbackmsg+=" - "
            fallbackmsg+="${kleur[LightGray]}${LOGmsg}${kleur[Color_Off]}"

            echo -e "${fallbackmsg}"
            echo $LOGmsg >> "${fallbackarpmonitorlog}"
          fi
     fi

     ## If $3 Greater than 0 then print to Console (Write-Host)
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

  arpmonitorlog="/home/"
  arpmonitorlog+=$gebruiker
  arpmonitorlog+="/Log/arpmonitor.log"
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
    whatmsg="initialdedup (-e) is not filled in, This is needed to place the file with unique entry's by arp-scan."
    parametererror+=$whatmsg
    parametererror+=$breken
    WriteLog 1 "$whatmsg" 0 Red
  fi
  if [ "$chkarp" = "" ]; then
    whatmsg="chkarp (-c) is not filled in, This is needed to place the interval arp-scans file."
    parametererror+=$whatmsg
    parametererror+=$breken
    WriteLog 1 "$whatmsg" 0 Red
  fi
  if [ "$chkdeduparp" = "" ]; then
    whatmsg="chkdeduparp (-u) is not filled in, This is needed to place the interval arp-scans file."
    parametererror+=$whatmsg
    parametererror+=$breken
    WriteLog 1 "$whatmsg" 0 Red
  fi
  echo "Aprmonitorlog: ${arpmonitorlog}";
  if [ "${arpmonitorlog}" = "" ]; then
    whatmsg="${arpmonitorlog} (-m) is not filled in, This is needed to place the interval arp-scans file."
    parametererror+=$whatmsg
    parametererror+=$breken
    WriteLog 1 "$whatmsg" 0 Red
  fi
  if [ "$parametererror" = "" ]; then
    whatmsg="If you are running this script under a particular user, you can use homedir (-h yes) to let the file location fill in automaticly."
    parameterTIP+=$whatmsg
    parameterTIP+=$breken
    WriteLog 1 "$whatmsg" 0 LightBlue
  fi
fi
if [ "$LANinterface" = "" ]; then
  whatmsg="LANinterface i(-l) is empty, Please specify the Lan interface you wnat to use for the arp-scan."
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
elif (( Interval < 100 )); then
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
  whatmsg="minpercentage (-p) can only contain numbers between 1 and 100 (%percent%). This parameter gives you control when there is a too low percentage of IP adresses and Mac adresses changed. Assuming standard 70."
  parameterwarning+=$whatmsg
  parameterwarning+=$breken

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Yellow
  fi
  minpercentage=70
elif (( minpercentage < 1 )) || (( minpercentage > 100 )); then
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
  parameterTIP+=$whatmsg
  parameterTIP+=$breken
  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Cyan
  fi
  macdifferent=1
elif [ "$macdifferent" = "NO" ] || [ "$macdifferent" = "N" ] || [ "$macdifferent" = "NEE" ] || [ "$macdifferent" = "0" ]; then
  whatmsg="User does not want any differences in Mac Adresses (-f). macdifferent=0 --> User Does NOT have to define Percentage"
  parameterTIP+=$whatmsg
  parameterTIP+=$breken
  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Green
  fi
  macdifferent=0
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

    echo "macdifferenpercent: $macdiffpercent"

    if (( DebugLevel > 0 )); then
      WriteLog 1 "$whatmsg" 0 Yellow
    fi
  elif (( macdiffpercent < 1 )) || (( macdiffpercent > 100 )); then
    whatmsg="macdiffpercent (-t) can only contain numbers between 1 and 100 (percent)(%). With this parameter you can control how many Mac adresses may be different if you have choosen mac different to yes (or 1). asssuming default percentage: 80."
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
  whatmsg="maxloops (-o) can only contain numbers. Here you can specify how many loops this routine can do before it stops with a maximum of 600 times. Assuming default of 336."
  parameterwarning+=$whatmsg
  parameterwarning+=$breken
  maxloops=336
elif (( maxloops > 600 )); then
   whatmsg="maxloops (-o) has a maximum of 600 loops, the value is too high, changing it to the maximum of 600."
   parameterwarning+=$whatmsg
   parameterwarning+=$breken
   maxloops=600
   if (( DebugLevel > 0 )); then
     WriteLog 1 "$whatmsg" 0 Yellow
   fi
fi

## Extensive Debugging
#
if (( DebugLevel > 5 )); then
  echo "IPRange if: $iprange";
fi

## Test IP Adress, we assume an error until proven otherwise
#
let IPtest=0
if valid_ip $iprange; then
  ## IP address is ok, now strip the last digit
  #
  let "IPtest+=1"

  ## Split the IP adress up into an array by '.'
  #
  IFS='.'
  read -ra IPNR <<< "$iprange"

  ## Debugging
  #
  if (( DebugLevel > 5 )); then
    echo "IPRange if: $iprange";
  fi

  for ipcount in "${IPNR[@]}"
  do
    # process "$ipcount"
    if (( DebugLevel > 2 )); then
       whatmsg="Processing ipcount: ${ipcount}"
       WriteLog 1 "$whatmsg" 1 Cyan
    fi
  done
  if (( ipcount > 3 )) then
    whatmsg="Entered IP address correct (-r), we will strip the last digit, so we can loop through the possible numbers."
    parameterwarning+=$whatmsg
    parameterwarning+=$breken

    if (( DebugLevel > 0 )); then
      WriteLog 1 "$whatmsg" 1 Green
    fi
    $iprange=${IPNR[0]}
    $iprange+="."
    $iprange+=${IPNR[1]}
    $iprange+="."
    $iprange+=${IPNR[2]}
    $iprange+="."

    let "IPtest+=1"
  fi
else
  whatmsg="Invalid IP Address in IPRange (-r). IP adress must be (4 Digits with points as limiters) 1.1.1.0 or 192.168.10.0, please correct the input for the IP Range."
  parametererror+=$whatmsg
  parametererror+=$breken
  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Red
  fi
  let IPtest=0
fi

## See if subnet is filled and within specs
#
if ! [[ "$ipsubnet" =~ ^[0-9]+$ ]]; then
  whatmsg="ipsubnet (-s) can only contain numbers. Here you can specify the subnet of the network. Assuming default of 24."
  parameterwarning+=$whatmsg
  parameterwarning+=$breken
  ipsubnet=24
elif (( ipsubnet > 32 )); then
   whatmsg="ipsubnet (-s) cannot be higher than 32. Assuming default of 24."
   parameterwarning+=$whatmsg
   parameterwarning+=$breken
   ipsubnet=24
   if (( DebugLevel > 0 )); then
     WriteLog 1 "$whatmsg" 0 Yellow
   fi
elif (( ipsubnet < 1 )); then
   whatmsg="ipsubnet (-s) cannot be lower than 1. Setting value to minimum: 1."
   parameterwarning+=$whatmsg
   parameterwarning+=$breken
   ipsubnet=1
   if (( DebugLevel > 0 )); then
     WriteLog 1 "$whatmsg" 0 Yellow
   fi
fi

## See if the maximum file size of the log file is correctly filled in
#
if ! [[ "$logmaxsize" =~ ^[0-9]+$ ]]; then
  whatmsg="logmaxsize (-x) can only contain numbers. Here you can specify the maximum file size of the arpmonitor log file. Assuming default of 1000000 bytes."
  parameterwarning+=$whatmsg
  parameterwarning+=$breken
  logmaxsize=1000000
elif (( logmaxsize > 20000000 )); then
   whatmsg="logmaxsize (-x) cannot be higher than 20 MB. Assuming default of 2000000 bytes."
   parameterwarning+=$whatmsg
   parameterwarning+=$breken
   logmaxsize=2000000
   if (( DebugLevel > 0 )); then
     WriteLog 1 "$whatmsg" 0 Yellow
   fi
elif (( logmaxsize < 100000 && DebugLevel < 3 )); then
   whatmsg="logmaxsize (-x) cannot be lower than 100000 bytes. Setting value to minimum: 100000 bytes."
   parameterwarning+=$whatmsg
   parameterwarning+=$breken
   logmaxsize=100000
   if (( DebugLevel > 0 )); then
     WriteLog 1 "$whatmsg" 0 Yellow
   fi
elif (( logmaxsize < 1000000 && DebugLevel > 2 )); then
   ## https://tecadmin.net/double-parentheses-in-bash/
   #
   whatmsg="logmaxsize (-x) cannot be lower than 1000000 bytes, becease the debug level is high, the script will only be rotating the log. Setting value to minimum: 1000000 bytes."
   parameterwarning+=$whatmsg
   parameterwarning+=$breken
   logmaxsize=1000000
   if (( DebugLevel > 0 )); then
     WriteLog 1 "$whatmsg" 0 Yellow
   fi
else
   whatmsg="Something went wrong with logmaxsize (-x), assuming standard value of 1000000 bytes."
   parameterwarning+=$whatmsg
   parameterwarning+=$breken
   logmaxsize=10000000
   if (( DebugLevel > 0 )); then
     WriteLog 1 "$whatmsg" 0 Yellow
   fi

fi

## See if the maximum file size of the log file is correctly filled in
#
if ! [[ "$numberinstances" =~ ^[0-9]+$ ]]; then
  whatmsg="numberinstances (-n) can only contain numbers. Here you can specify how many processes of this script is running. When this number is exceeded, a new instance of this script will
not start. Assuming maximum instances of two(2)"
  parameterwarning+=$whatmsg
  parameterwarning+=$breken
  numberinstances=2
elif (( numberinstances > 20 )); then
   whatmsg="numberinstances (-n) cannot be higher than 20 instances. Assuming default maximum number of instances of 2."
   parameterwarning+=$whatmsg
   parameterwarning+=$breken
   numberinstances=2
   if (( DebugLevel > 0 )); then
     WriteLog 1 "$whatmsg" 0 Yellow
   fi
elif (( numberinstances == 0  )); then
   whatmsg="numberinstances (-n) is 0 (zero), instances check is OFF!. This can cause a lot of arpmonitor.bash instances!"
   parameterwarning+=$whatmsg
   parameterwarning+=$breken
   if (( DebugLevel > 0 )); then
     WriteLog 1 "$whatmsg" 0 Yellow
   fi
elif (( numberinstances < 0  )); then
   whatmsg="numberinstances (-n) cannot be lower than 0 instance(s). Setting value to minimum of: 0 instance(s) --> Check is OFF."
   parameterwarning+=$whatmsg
   parameterwarning+=$breken
   numberinstances=0
   if (( DebugLevel > 0 )); then
     WriteLog 1 "$whatmsg" 0 Yellow
   fi
fi

## Check if the needed directory's exists, if not warn the user
#
if [ -d "$initialarp" ]; then
  whatmsg="Directory: $initialarp does NOT exists, please create the directory! (option:-i)."
  parametererror+=$whatmsg
  parametererror+=$breken

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Red
  fi
fi
if [ -d "$initialdedup" ]; then
  whatmsg="Directory: $initialdedup does NOT exists, please create the directory! (option:-d)."
  parametererror+=$whatmsg
  parametererror+=$breken

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Red
  fi
fi
if [ -d "$chkarp" ]; then
  whatmsg="Directory: $chkarp does NOT exists, please create the directory! (option:-c)."
  parametererror+=$whatmsg
  parametererror+=$breken

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Red
  fi
fi
if [ -d "$chkdeduparp" ]; then
  whatmsg="Directory: $chkdeduparp does NOT exists, please create the directory! (option:-u)."
  parametererror+=$whatmsg
  parametererror+=$breken

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Red
  fi
fi
if [ -d "${arpmonitorlog}" ]; then
  whatmsg="Directory: ${arpmonitorlog} does NOT exists, please create the directory! (option:-m)."
  parametererror+=$whatmsg
  parametererror+=$breken

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Red
  fi
fi
if [ -d "${logmaxsize}" ]; then
  whatmsg="Directory: ${arpmonitorlog} does NOT exists, please create the directory! (option:-x)."
  parametererror+=$whatmsg
  parametererror+=$breken

  if (( DebugLevel > 0 )); then
    WriteLog 1 "$whatmsg" 0 Red
  fi
fi

if [ "$parameterwarning" != "" ]; then
  echo -e "${kleur[Black]}${kleur[OnYellow]}"
  echo "${divider}"
  echo "Parameter Warnings (Script will execute)"
  echo -e "${divider} ${kleur[Color_Off]}"
  if (( DebugLevel > 0 )); then
    whatmsg="Parameter Warnings (Script will execute)"
    WriteLog 1 "$whatmsg" 0 LightBlue
    whatmsg="${divider}"
    WriteLog 1 "$whatmsg" 0 LightBlue
  fi

  ## Break Parameter warning in pieces through a symbol "|"
  #
  IFS=$breken read -ra WarningLines <<< "$parameterwarning"
  for warningline in "${WarningLines[@]}"
    do
      echo -e "${kleur[Color_Off]}${kleur[Yellow]}${warningline}"
      if (( DebugLevel > 0 )); then
        whatmsg="${warningline}"
        WriteLog 1 "$whatmsg" 0 LightBlue
      fi
    done
fi
if [ "$parameterTIP" != "" ]; then
  echo -e "${kleur[Black]}${kleur[OnWhite]}"
  echo "${divider}"
  echo "Parameter Tips (Script will execute)"
  echo -e "${divider} ${kleur[Color_Off]}"
  if (( DebugLevel > 0 )); then
    whatmsg="Parameter Tips (Script will execute)"
    WriteLog 1 "$whatmsg" 0 LightBlue
    whatmsg="${divider}"
    WriteLog 1 "$whatmsg" 0 LightBlue
  fi

  IFS=$breken read -ra TIPLines <<< "$parameterTIP"
  for TIPLine in "${TIPLines[@]}"
    do
      echo -e "${kleur[Color_Off]}${kleur[LightGray]}${TIPLine}"
      if (( DebugLevel > 0 )); then
        whatmsg="${TIPLine}"
        WriteLog 1 "$whatmsg" 0 LightBlue
      fi
    done

  if (( IPtest > 0 )) then
    echo -e "${kleur[White]}${kleur[OnBlue]}"
    echo "${divider}"
    echo "IP Calculation TIP (Script will execute)"
    echo -e "${divider} ${kleur[Color_Off]}"

    ## We can calculate the ip adres with the subnet
    #
    calcIP=$iprange
    calcIP+="/"
    calcIP+=$ipsubnet

    ipcalc "$calcIP"

    whatmsg="ipsubnet (-s) is correct with the value of: ${ipsubnet} "
    parameterTIP+=$whatmsg
    parameterTIP+=$breken
    WriteLog 1 "$whatmsg" 0 LightBlue
  fi
fi

if [ "$parametererror" != "" ]; then
  echo -e "${kleur[White]}${kleur[OnRed]}"
  echo "${divider}"
  echo "Parameter Error (Script will STOP!)"
  echo -e "${divider} ${kleur[Color_Off]}"
  if (( DebugLevel > 0 )); then
    whatmsg="Parameter Error (Script will STOP!)"
    WriteLog 1 "$whatmsg" 0 LightBlue
    whatmsg="${divider}"
    WriteLog 1 "$whatmsg" 0 LightBlue
  fi

  IFS=$breken read -ra ErrorLines <<< "$parametererror"
  for ErrorLine in "${ErrorLines[@]}"
    do
      echo -e "${kleur[Color_Off]}${kleur[LightRed]}${ErrorLine}"
      if (( DebugLevel > 0 )); then
        whatmsg="${ErrorLine}"
        WriteLog 1 "$whatmsg" 0 LightBlue
      fi
    done

  ## Print the help lines
  #
  echo -e "${kleur[LightBlue]} ${divider}"
  echo "Parameter errors or parameters missing! Explenation:"
  echo ""
  echo "-h : Homedir       --> This means you will be using the script under a particular user."
  echo "                       The parameters: -i -c -u -e -m will be filled in automaticly with /home/USER/...."
  echo "${divider}"
  echo "These parameters need to be filled in when (-h) Homedir is not used:"
  echo ""
  echo "-i: Initialarp      --> This is the file location of the initial arp-scan (With directory)."
  echo "-d: Initialdedup    --> This is the file location of the initial arp-scan (With directory)."
  echo "-c: ChkArp          --> This is the file location of the interval checks of arp-scan go (With directory)."
  echo "-e: Chkdeduparp     --> This is the file location of the deduplicated file of the interval checks of arp-scan go (With directory)."
  echo "${divider}"
  echo "-m: Arpmonitorlog   --> This is the file location where the log file goes. (With directory)."
  echo "-x: Logmaxsize      --> Maximum File size of log file before we make a new log file"
  echo "${divider}"
  echo "These parameters always need to be filled in:"
  echo "${divider}"
  echo "-l: LANinterface    --> Name of the lan interface."
  echo "-v: Interval        --> The time the script has to wait before doing another arp-scan in seconds."
  echo "-d: DebugLevel      --> how much logging must be done to the logging file (0/1/2/3)"
  echo "-p: minpercentage   --> Minimal percentage that has too be the same Mac and Ip adress as the initial scan"
  echo "${divider}"
  echo "-f: macdifferent    --> Must every Mac-adress be the same, or do we handle the check in a percentage?"
  echo "-t: macdiffpercent  --> If you have used parameter (-f YES) then you need to fill in a percentage to determine how many mac adresses may be different."
  echo "${divider}"
  echo "-g: gracefultime    --> How many seconds does a Virtual Machine get to gracefully shutdown before a hard poweroff is given (in seconds)."
  echo "-o: maxloops        --> The maximum loops this script may run."
  echo "-r: IP Range        --> This is the range of IP adresses (192.168.8.xxx) that the app will scan. Please enter ip like: 10.10.10.0"
  echo "-s: IP Subnet       --> This is the subnet of the IP Range. Example: /24 = 255.255.255.0 -OR- /17 = 255.255.128.0"
  echo "${divider}"
  echo "-n: numberinstances --> Maximum number of instances running of this script under the running user (0 = OFF)"
  echo -e "${kleur[Color_Off]}"
  exit
fi

## We will contineu the script
#
echo -e "${kleur[Cyan]} ${divider}"
if (( DebugLevel > 0 )); then
  whatmsg="Received following parameters"
  WriteLog 1 "$whatmsg" 1 Cyan
fi

if (( DebugLevel > 0 )); then
  whatmsg="${divider}"
  WriteLog 1 "$whatmsg" 1 Cyan
else
  echo -e "${kleur[Cyan]} ${divider}"
fi

if (( DebugLevel > 0 )); then
  whatmsg="-i: Initialarp      (file)   : $initialarp"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -i: Initialarp      ${kleur[Purple]} (file)   ${kleur[Cyan]}: $initialarp"

if (( DebugLevel > 0 )); then
  whatmsg="-d: Initialdedup    (file)   : $initialdedup"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -d: Initialdedup    ${kleur[Purple]} (file)   ${kleur[Cyan]}: $initialdedup"

if (( DebugLevel > 0 )); then
  whatmsg="-c: ChkArp          (file)   : $chkarp"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -c: ChkArp          ${kleur[Purple]} (file)   ${kleur[Cyan]}: $chkarp"

if (( DebugLevel > 0 )); then
  whatmsg="-e: chkdeduparp     ${kleur[Purple]} (file)   ${kleur[Cyan]}: $chkdeduparp"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -e: chkdeduparp     ${kleur[Purple]} (file)   ${kleur[Cyan]}: $chkdeduparp"

if (( DebugLevel > 0 )); then
  whatmsg="${divider}"
  WriteLog 1 "$whatmsg" 1 Cyan
else
  echo -e "${kleur[Cyan]} ${divider}"
fi

if (( DebugLevel > 0 )); then
  whatmsg="-m: Arpmonitorlog   (file)   : $arpmonitorlog"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -m: Arpmonitorlog   ${kleur[Purple]} (file)   ${kleur[Cyan]}: $arpmonitorlog"

if (( DebugLevel > 0 )); then
  whatmsg="-x: Logmaxsize      (number) : $logmaxsize"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -x: Logmaxsize      ${kleur[Purple]} (number) ${kleur[Cyan]}: $logmaxsize"

if (( DebugLevel > 0 )); then
  whatmsg="${divider}"
  WriteLog 1 "$whatmsg" 1 Cyan
else
  echo -e "${kleur[Cyan]} ${divider}"
fi

if (( DebugLevel > 0 )); then
  whatmsg="-l: LANinterface    (name)   : $LANinterface"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -l: LANinterface    ${kleur[Purple]} (name)   ${kleur[Cyan]}: $LANinterface"

if (( DebugLevel > 0 )); then
  whatmsg="-v: Interval        (seconds): $Interval"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -v: Interval        ${kleur[Purple]} (seconds)${kleur[Cyan]}: $Interval"

if (( DebugLevel > 0 )); then
  whatmsg="-d: DebugLevel      (number) : $DebugLevel"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -d: DebugLevel      ${kleur[Purple]} (number) ${kleur[Cyan]}: $DebugLevel"

if (( DebugLevel > 0 )); then
  whatmsg="-p: minpercentage   (number) : $minpercentage"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -p: minpercentage   ${kleur[Purple]} (number) ${kleur[Cyan]}: $minpercentage"

if (( DebugLevel > 0 )); then
  whatmsg="${divider}"
  WriteLog 1 "$whatmsg" 1 Cyan
else
  echo -e "${kleur[Cyan]} ${divider}"
fi

echo -e "${kleur[Cyan]} -f: macdifferent    ${kleur[Purple]} (bolean) ${kleur[Cyan]}: $macdifferent"

if (( macdifferent < 1 )); then
  echo -e "${kleur[Cyan]} -t: macdiffpercent  ${kleur[Purple]} (number) ${kleur[DarkGray]}: Not Needed"
  if (( DebugLevel > 0 )); then
    whatmsg="-t: macdiffpercent  (number) : Not Needed"
    WriteLog 1 "$whatmsg" 0 Cyan
  fi
else
  echo -e "${kleur[Cyan]} -t: macdiffpercent  ${kleur[Purple]} (number) ${kleur[Cyan]}: $macdiffpercent"
  if (( DebugLevel > 0 )); then
    whatmsg="-t: macdiffpercent  (number) : $macdiffpercent"
    WriteLog 1 "$whatmsg" 0 Cyan
  fi
fi

if (( DebugLevel > 0 )); then
  whatmsg="${divider}"
  WriteLog 1 "$whatmsg" 1 Cyan
else
  echo -e "${kleur[Cyan]} ${divider}"
fi

if (( DebugLevel > 0 )); then
  whatmsg="-g: gracefultime    (seconds): $gracefultime"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -g: gracefultime    ${kleur[Purple]} (seconds)${kleur[Cyan]}: $gracefultime"

if (( DebugLevel > 0 )); then
  whatmsg="-o: maxloops        (number) : $maxloops"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -o: maxloops        ${kleur[Purple]} (number) ${kleur[Cyan]}: $maxloops"

if (( DebugLevel > 0 )); then
  whatmsg="-r: IP Range        (number) : $iprange"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -r: IP Range        ${kleur[Purple]} (number) ${kleur[Cyan]}: $iprange"

if (( DebugLevel > 0 )); then
  whatmsg="-s: IP Subnet       (number) : $ipsubnet"
  WriteLog 1 "$whatmsg" 0 Cyan
fi
echo -e "${kleur[Cyan]} -s: IP Subnet       ${kleur[Purple]} (number) ${kleur[Cyan]}: $ipsubnet"

if (( DebugLevel > 0 )); then
  whatmsg="${divider}"
  WriteLog 1 "$whatmsg" 1 Cyan
else
  echo -e "${kleur[Cyan]} ${divider}"
fi

## Number of instances is a seperate line with a check inside it
#
#if (( DebugLevel > 0 )); then
#  whatmsg="-n: numberinstances (number) : $numberinstances"
#  WriteLog 1 "$whatmsg" 0 Cyan
#fi
#echo -e "${kleur[Cyan]} -n: numberinstances ${kleur[Purple]} (number) ${kleur[Cyan]}: $numberinstances"

## Record the number of running processes for arpmonitor.bash
#
processen=$(ps -x | grep arpmonitor)
nrprocess=$(echo "$processen" | wc -l)
actualprocesses=$nrprocess

if (( actualprocesses < 0 )); then
  actualprocesses=0
  if (( DebugLevel > 2 )); then
    whatmsg="Integer actualprocesses is below 0, set actualprocesses to 0 (zero)"
    WriteLog 1 "$whatmsg" 1 LightBlue
  fi
fi

if (( numberinstances > 0 )); then
  ## Number of instances is greater than 0, check how many instances are active of arpmonitor.bash script
  #
  if (( DebugLevel > 0 )); then
    whatmsg="-n: numberinstances (number) : $numberinstances (Running: $actualprocesses)"
    WriteLog 1 "$whatmsg" 0 Cyan
  fi
  echo -e "${kleur[Cyan]} -n: numberinstances ${kleur[Purple]} (number) ${kleur[Cyan]}: $numberinstances ${kleur[DarkGray]} (Running: $actualprocesses)"

  if (( DebugLevel > 2 )); then
    whatmsg="Check how many instances are running of this script under this user, number: $actualprocesses"
    WriteLog 1 "$whatmsg" 0 LightBlue
  fi

  if (( actualprocesses > numberinstances )); then
    ## To many processes running of arpmonitor.bash, exit the script
    #
    whatmsg="Number of running processes of arpmonitor.bash: $actualprocesses is greater than the maximum allowed running processes: $numberinstances"
    WriteLog 1 "$whatmsg" 1 Red

    exit;
  fi
else
  ## Display the 0 (zero) in dark gray, becease it is not processed
  #
  echo -e "${kleur[Cyan]} -n: numberinstances ${kleur[Purple]} (number) ${kleur[DarkGray]}: $numberinstances (OFF)"

  if (( DebugLevel > 0 )); then
    whatmsg="Check on how many instances are running is switches OFF! (Actual Running processes of arpmonitor.bash: $actualprocesses"
    WriteLog 1 "$whatmsg" 0 LightBlue
  fi
fi

if (( DebugLevel > 0 )); then
  whatmsg="Start the Arp Monitor routine, first do a initial arp-scan"
  WriteLog 1 "$whatmsg" 0 LightBlue
fi

## Make the scan parameter compete with IP Subnet
#
SCANiprange="${iprange}/${ipsubnet}"

## Print IP Range and print it to the screen and Log file
#
if (( DebugLevel > 0 )); then
  whatmsg="Scan IP Range: $SCANiprange --> Dump result to file: $initialarp"
  WriteLog 1 "$whatmsg" 1 LightBlue
fi

## Get the initial Mac adresses of the network (Only Once and save it)
#
arp-scan -I $LANinterface --rtt --format='|${ip;-15}|${mac}|' "${SCANiprange}" > "${initialarp}"

if (( DebugLevel > 0 )); then
  whatmsg="Remove the possible double entry's from the initial ARP Scan"
  WriteLog 1 "$whatmsg" 0 LightBlue
fi

if (( DebugLevel > 0 )); then
  whatmsg="Start the Arp Monitor routine, first do a initial arp-scan"
  WriteLog 1 "$whatmsg" 0 LightBlue
fi

## Insert the arp initial file into an array, and break each line with WhiteSpace
#
IFS=$'\n' read -d '' -r -a initiallines < "$initialarp"

## Remove the double entry's
#
count=0
initialduplicates=0

if (( DebugLevel > 0 )); then
  whatmsg="## Deduplication of initial Arp-scan results"
  WriteLog 1 "$whatmsg" 0 LightBlue
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
      whatmsg="Remember: $remember --> $initialline --> $tellen"
      WriteLog 1 "$whatmsg" 0 LightBlue
    fi

    if [ "$remember" = "$initialline" ]; then
      let found=1
      if (( DebugLevel > 1 )); then
        whatmsg="## Found a duplicate line: $initialline --> Deduplicate"
        WriteLog 1 "$whatmsg" 0 LightBlue
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

## Here is the endless loop with a maximum, here we will check the IP adresses
## and Mac adresses of the network and will make a check on the two lists
#
let endless=0
while [ $endless -lt $maxloops ]; do
        if (( DebugLevel > 0 )); then
          #echo "Loop through each line of initial arp-scan" >> "${arpmonitorlog}"
          whatmsg="Loop through each line of initial arp-scan"
          WriteLog 1 "$whatmsg" 0 LightBlue
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
                 whatmsg="initial IP:  ${INITIALADDR[1]} - count: $count"
                 WriteLog 1 "$whatmsg" 0 LightBlue
                 whatmsg="initial Mac: ${INITIALADDR[2]} - count: $count"
                 WriteLog 1 "$whatmsg" 0 LightBlue
           fi

           InitialIP[$count]=${INITIALADDR[1]}
           InitialMac[$count]=${INITIALADDR[2]}
           fullempty=${INITIALADDR[1]}

           if [ "$fullempty" != "" ]; then
                  ## Only count the filled lines
                  #
                  countfilledlines=$((countfilledlines + 1))
                  if (( DebugLevel > 0 )); then
                        whatmsg="Filled InitialIP counted: ${InitialIP[$count]} - ${InitialMac[$count]}"
                        WriteLog 1 "$whatmsg" 0 LightBlue
                  fi

           fi

           if (( DebugLevel > 5 )); then
             echo "Initial IP: ${InitialIP[$count]}"
             echo "Initial Mac: ${InitialMac[$count]}"
           fi

           count=$((count + 1))
        done

        ## Sleep before doing checkups
        #
        if (( DebugLevel > 0 )); then
          whatmsg="Sleeping $Interval seconds before next interval check...."
          WriteLog 1 "$whatmsg" 1 LightBlue
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
        if (( DebugLevel > 0 )); then
          whatmsg="## Deduplication of Returning Arp-scan results"
          WriteLog 1 "$whatmsg" 0 LightBlue
        fi

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
                if (( DebugLevel > 2 )); then
                  whatmsg="Remember: $remember --> $initialline --> $tellen"
                  WriteLog 1 "$whatmsg" 0 LightBlue
                fi

                if [ "$remember" = "$chkline" ]; then
                  let found=1
                  if (( DebugLevel > 0 )); then
                        whatmsg="## Found a duplicate line: $chkline, Let's Dedupe IT! ($chkduplicates)"
                        WriteLog 1 "$whatmsg" 0 LightBlue
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
        if (( DebugLevel > 5 )); then
            whatmsg="Sleeping for Debug purpuses...."
            WriteLog 1 "$whatmsg" 0 LightBlue
            sleep 1
          fi
        done

        ## Read the deduplicated file
        #
        IFS=$'\n' read -d '' -r -a chklines < "$chkdeduparp"

        ## Debug purpeses, see all the lines
        #
        if (( DebugLevel > 2 )); then
          whatmsg="${lines[@]}"
          WriteLog 1 "$whatmsg" 1 LightBlue
        fi

        ## Loop through the lines of interval arp-scan so we can see if the ip adresses and mac adresses still match
        #
        let countmacok=0
        let countmactotal=0
        let countmacfault=0
        let coundIPtotal=0
        let countIPok=0
        let countIPfault=0

        for chkline in "${chklines[@]}"
        do
           # do whatever on "$chkline" here
           if (( DebugLevel > 2 )); then
                 whatmsg="CheckLine: $chkline"
                 WriteLog 1 "$whatmsg" 0 LightBlue
           fi

           ## Split the string with delimiter P|pe from string $chkline
           #
           IFS='|' read -ra CHKADDR <<< "$chkline"

           chkIP=${CHKADDR[1]}
           chkMac=${CHKADDR[2]}

           if (( DebugLevel > 2 )); then
                 whatmsg="CheckIP: $chkIP"
                 WriteLog 1 "$whatmsg" 0 LightBlue
                 whatmsg="Check Mac: $chkMac"
                 WriteLog 1 "$whatmsg" 0 LightBlue
           fi

           if [ "$chkIP" != "" ]; then
                 ## Check the IP adresses and Mac adresses with the initial Arp-scan
                 #
                 let tellen=0
                 coundIPtotal=$((coundIPtotal +1))

                 while [ $tellen -lt $count ]; do
                   ## Little less logging may be done, lets regulated it with a parameter
                   #
                   if (( DebugLevel > 2 )); then
                         whatmsg="Checking IP and Mac against original IP and Mac $tellen (${chkIP} : ${InitialIP[$tellen]} /
 ${chkMac} : ${InitialMac[$tellen]} "
                         WriteLog 1 "$whatmsg" 0 LightBlue
                   fi

                   initIP=${InitialIP[$tellen]}

                   if [ "$chkIP" = "$initIP" ]; then
                         countIPok=$((countIPok +1))

                         ## Do some logging if requested
                         #
                         if (( DebugLevel > 2 )); then
                           whatmsg="found $chkIP - $initIP - Checking if Mac adress is correct...."
                           WriteLog 1 "$whatmsg" 0 LightBlue
                         fi

                         initMac=${InitialMac[$tellen]}

                         if [ "$chkMac" = "$initMac" ]; then
                          if (( DebugLevel > 2 )); then
                                 whatmsg="Mac adress: $chkMac is the same as: $initMac"
                                 WriteLog 1 "$whatmsg" 0 LightBlue
                           fi
                           countmacok=$((countmacok + 1))
                         else
                           if (( DebugLevel > 1 )); then
                                 whatmsg="Mac adress: $chkMac is different: $initMac"
                                 WriteLog 1 "$whatmsg" 0 LightBlue
                           fi

                           countmacfault=$((countmacfault + 1))
                         fi
                         countmactotal=$((countmactotal + 1))
                   else
                         countIPfault=$((countIPfault +1))
                   fi
                   let tellen=tellen+1
                 done
          fi
        done

        if (( DebugLevel > 0 )); then
          prnDEBUG=1
        else
          prnDEBUG=0
        fi

        whatmsg="Initial ARP count with duplicates: ${initialcount}"
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        whatmsg="CountMac Total: ${countmactotal}"
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        whatmsg="CountMac OK: ${countmacok}"
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        whatmsg="CountMac Fault: ${countmacfault}"
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        whatmsg="Count Filled Lines: ${countfilledlines}"
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        whatmsg="Initial Duplicate lines found: ${initialduplicates}"
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        whatmsg="Re-accuring Duplicates found: ${chkduplicates}"
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        whatmsg="Calculate percentage IP adresses found: countfilledlines: $countfilledlines -->  count IP ok: $countIPok / Count IP Total: $coundIPtotal"
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        if (( countfilledlines > 0 )); then
          howmanyprocentIP=$((100*${countIPok}/${coundIPtotal}))
        else
          howmanyprocentIP=0
        fi

        whatmsg="Calculate percentage IP adresses found: countfilledlines: $countfilledlines --> Count MAC adresses ok: $countmacok / Count MAc adresses Total: $countmactotal "
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        if (( countfilledlines > 0 )); then
          howmanyprocentMAC=$((100*${countmacok}/${countmactotal}))
        else
          howmanyprocentMAC=0
        fi

        whatmsg="How many IP adresses percent is found from the initial arp-scan: ${howmanyprocentIP} (with the interval IP adresses scan)"
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        whatmsg="How many MAC adresses percent is found from the initial arp-scan: ${howmanyprocentMAC} (with the interval Mac adresses Scan)"
        WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

        ## Check if the percentage is less than the minimum percentage, if it is less take action.
        #
        let takeaction=0

        if [ $howmanyprocentIP -lt $minpercentage ]; then
          ## Less than the minimal percentage is there, take action!
          whatmsg="The found ip adres percentage: $howmanyprocentIP is lower than $minpercentage, take action!"
          WriteLog $prnDEBUG "$whatmsg" 1 LightRed

          let takeaction=1
        else
          ## Within percentage, all is ok!
          whatmsg="The found ip adres percentage: $howmanyprocentIP is higher than $minpercentage, IP Adresses is well!"
          WriteLog $prnDEBUG "$whatmsg" 1 Green

          #takeaction=0
        fi
        if [ $howmanyprocentMAC -lt $minpercentage ]; then
          ## Less than the minimal percentage is there, take action!
          whatmsg="The found correct MAC adres percentage: $howmanyprocentMAC is lower than $minpercentage, take action!"
          WriteLog $prnDEBUG "$whatmsg" 1 LightRed

          let takeaction=1
        else
          ## Within percentage, all is ok!
          whatmsg="The found MAC adres percentage: $howmanyprocentMAC is higher than $minpercentage, Mac Adresses is well!"
          WriteLog $prnDEBUG "$whatmsg" 1 Green

          #takeaction=0
        fi

        ## Check if an mac adress may change
        #
        if [ $macdifferent -eq 0 ]; then
          ## All mac adresses must be the same on the same ip adressses
          whatmsg="All Mac adresses MUST be the same, check if there are faulty MAc adresses"
          WriteLog $prnDEBUG "$whatmsg" 1 LightBlue

          if [ $countmacfault -gt 0 ]; then
                ## There is a problem, an mac adress is different
                whatmsg="Number of faulty mac adresses: $countmacfault, None is the Rule, take action!"
                WriteLog $prnDEBUG "$whatmsg" 1 LightRed

                let takeaction=1
          else
                whatmsg="All Mac adresses are the same as the initial readout by arp-scan"
                WriteLog $prnDEBUG "$whatmsg" 1 Green
          fi
        else
          ## Yes there may be a difference, but how many percent?
          ## $macdiffpercent
          #
          if (( DebugLevel > 0 )); then
                whatmsg="Not all Mac adresses in the network have to be exactly the same, a minimal percentage is given: $diffprocent"
                WriteLog $prnDEBUG "$whatmsg" 1 Cyan
          fi

          diffprocent=$((100*$countmacok/$countmactotal))
          if [ $diffprocent -lt $macdiffpercent ]; then
                ## Less than the minimal percentage is there, take action!
                if (( DebugLevel > 0 )); then
                  whatmsg="The Mac pass percentage: $macdiffpercent is lower than $diffprocent, take action!"
                  WriteLog $prnDEBUG "$whatmsg" 1 Red
                fi
                let takeaction=1
          else
                ## Within percentage, all is ok!
                if (( DebugLevel > 0 )); then
                  whatmsg="The Mac pass percentage: $howmanyprocent is higher than $minpercentage, all is well!"
                  WriteLog $prnDEBUG "$whatmsg" 1 Green
                fi

                #let takeaction=0
          fi
        fi

        whatmsg="Do we need to take action (0 = No / 1 = Yes)? : $takeaction"
        WriteLog $prnDEBUG "$whatmsg" 1 Cyan

        if (( takeaction > 0 )); then
          if (( DebugLevel > 0 )); then
                whatmsg="Do we need to take action (0 = No / 1 = Yes)? : $takeaction --> Yes! we need to take action!"
                WriteLog $prnDEBUG "$whatmsg" 1 Yellow
          fi

          ## Fill a string to see if there are running Vm's
          #
          RunningVMs=$(VBoxManage list runningvms)

          if (( DebugLevel > 0 )); then
                whatmsg="Found the following machines running: $RunningVMs"
                WriteLog $prnDEBUG "$whatmsg" 1 Cyan
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
                  whatmsg="Pressing ACPI Powerbutton for Virtual Machine:  $VboxName to gracefully shutdown the machine"
                  WriteLog $prnDEBUG "$whatmsg" 1 Cyan
                fi
                ResultPWRButton=$(VBoxManage controlvm $VboxName acpipowerbutton)

                if (( DebugLevel > 1 )); then
                  whatmsg="Give time for the Virtual Machine:  $VboxName to gracefully shutdown, sleep for $gracefultime seconds"
                  WriteLog $prnDEBUG "$whatmsg" 0 Cyan
                  whattmsg=$ResultPWRButton
                  WriteLog $prnDEBUG "$whatmsg" 0 Cyan
                fi
                sleep $gracefultime

                if (( DebugLevel > 1 )); then
                  whatmsg="To be fully sure, poweroff the VM : ${VboxName}"
                  WriteLog $prnDEBUG "$whatmsg" 0 Cyan
                fi
                ResultPowerOFF=$(VBoxManage controlvm $VboxName poweroff)

                ## Stop the endless routine for this machine, it does not run anymore
                #
                let endless=endless+1000
                if (( DebugLevel > 1 )); then
                  whatmsg="VM has been shut down"
                  WriteLog $prnDEBUG "$whatmsg" 0 Cyan
                  whatmsg=$ResultPowerOFF
                  WriteLog $prnDEBUG "$whatmsg" 0 Cyan
                fi
          else
                if (( DebugLevel > 0 )); then
                  whatmsg="There are no Running VM's found, we do not need todo anything"
                  WriteLog $prnDEBUG "$whatmsg" 0 Cyan
                fi
          fi
        else
          if (( DebugLevel > 0 )); then
                whatmsg="Do we need to take action (0 = No / 1 = Yes)? : $takeaction --> No, no action needed!"
                WriteLog $prnDEBUG "$whatmsg" 0 Cyan
          fi
          ## Fill a string to see if there are running Vm's
          #
          RunningVMs=$(VBoxManage list runningvms)
          if (( DebugLevel > 0 )); then
                whatmsg="Found the following machines running: $RunningVMs"
                WriteLog $prnDEBUG "$whatmsg" 0 Cyan
          fi
        fi
  let endless=endless+1
done
exit
