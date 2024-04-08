You need to install bash

pkg install bash

You need to install arp-scan

pkg install apr-scan

You need to edit /etc/newsyslog.conf to keep the log rotated
Add the following line
/var/log/arpmonitor.log                 640  7     1000 *     JC
