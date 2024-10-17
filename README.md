You need to install bash

pkg install bash

You need to install arp-scan

pkg install apr-scan

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
