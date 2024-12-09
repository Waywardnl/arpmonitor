You need to install bash

pkg install bash

You need to install arp-scan

pkg install arp-scan

Optional, but handy you need ipcalc

pkg install ipcalc

You need to edit /etc/newsyslog.conf to keep the log rotated
Add the following line
/var/log/arpmonitor.log                 640  7     1000 *     JC


 Received following parameters

 -i: Initialarp       (file)   : /home/USB/Data/initialarp.dat
 -d: Initialdedup     (file)   : /home/USB/Data/initialarpdedup.dat
 -c: ChkArp           (file)   : /home/USB/Data/arpscanning.dat
 -e: chkdeduparp      (file)   : /home/USB/Data/arpdedupscanning.dat

 -m: Arpmonitorlog    (file)   : /home/USB/Log/arpmonitor.log
 -x: Logmaxsize       (number) : 2000000

 -l: LANinterface     (name)   : bge0
 -v: Interval         (seconds): 100
 -d: DebugLevel       (number) : 4
 -p: minpercentage    (number) : 80

 -f: macdifferent     (bolean) : 1
 -t: macdiffpercent   (number) : 80

 -g: gracefultime     (seconds): 130
 -o: maxloops         (number) : 50
 -r: IP Range         (number) : 192.30.177.0
 -s: IP Subnet        (number) : 24

 -n: numberinstances  (number) : 15  (Running:        6)
Scan IP Range: 192.30.177.0/24 --> Dump result to file: /home/USB/Data/initialarp.dat

-------------------

Revised parameters:

/home/USB/arpmonitor.bash -h yes -l bge0 -v 90 -d 2 -p 75 -f yes -t 75 -g 130 -o 2 -r 192.30.177.0 -s 24 -n 10 -x 500000
Debuglevel: 2
tar: Removing leading '/' from member names
a home/USB/Log/arpmonitor.log
Removed: /home/USB/Log/arpmonitor(log)_Monday-02-December-2024--02-29-46.tar

-----------------------------------------------------------
Parameter Warnings (Script will execute)
-----------------------------------------------------------
[Warning]Interval (-v) has a minimum of 300 seconds waiting time (5 minutes), Assuming the minimal value: 300 seconds.
Something went wrong with logmaxsize (-x), assuming standard value of 1000000 bytes.

-----------------------------------------------------------
Parameter Tips (Script will execute)
-----------------------------------------------------------
User is ok with some Mac adresses to be different (-f). macdifferent=1 --> User also has to define percentage

-----------------------------------------------------------
IP Calculation TIP (Script will execute)
-----------------------------------------------------------
Address:   192.30.177.0         11000000.00011110.10110001. 00000000
Netmask:   255.255.255.0 = 24   11111111.11111111.11111111. 00000000
Wildcard:  0.0.0.255            00000000.00000000.00000000. 11111111
=>
Network:   192.30.177.0/24      11000000.00011110.10110001. 00000000
HostMin:   192.30.177.1         11000000.00011110.10110001. 00000001
HostMax:   192.30.177.254       11000000.00011110.10110001. 11111110
Broadcast: 192.30.177.255       11000000.00011110.10110001. 11111111
Hosts/Net: 254                   Class C

 -----------------------------------------------------------
Received following parameters
-----------------------------------------------------------
 -i: Initialarp       (file)   : /home/USB/Data/initialarp.dat
 -d: Initialdedup     (file)   : /home/USB/Data/initialarpdedup.dat
 -c: ChkArp           (file)   : /home/USB/Data/arpscanning.dat
 -e: chkdeduparp      (file)   : /home/USB/Data/arpdedupscanning.dat
-----------------------------------------------------------
 -m: Arpmonitorlog    (file)   : /home/USB/Log/arpmonitor.log
 -x: Logmaxsize       (number) : 10000000
-----------------------------------------------------------
 -l: LANinterface     (name)   : bge0
 -v: Interval         (seconds): 300
 -d: DebugLevel       (number) : 2
 -p: minpercentage    (number) : 75
-----------------------------------------------------------
 -f: macdifferent     (bolean) : 1
 -t: macdiffpercent   (number) : 75
-----------------------------------------------------------
 -g: gracefultime     (seconds): 130
 -o: maxloops         (number) : 2
 -r: IP Range         (number) : 192.30.177.0
 -s: IP Subnet        (number) : 24
-----------------------------------------------------------
 -n: numberinstances  (number) : 10  (Running:        5)

