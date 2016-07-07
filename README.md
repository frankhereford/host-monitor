# host-monitor

#### Simple host CPU, memory and traffic monitoring
Usage charts generated with [rrdtool](http://oss.oetiker.ch/rrdtool/).

#### How to run:
     docker run -d -v rrd:/var/www/html --cap-add=NET_ADMIN --net=host --name=monitor monitor

Web pages with usage charts will be updated every minute inside `rrd` volume

Build it for testing: docker run -it --rm -v rrd:/var/www/html --net=host --name=monitor monitor

ZFS notes:

pool:
zpool iostat -y 3 1 # no matter the sample window, you still get a per second value, interesting for rates?

zpool list -H



same gig:

zpool list -H -o capacity,fragmentation twinfalls


zfs list -H -p -t snapshot  # look below for what you can do

zfs list -p -o used -t snapshot # sum of all snapshot usage if summed, or clones, or whatever, change the type

zfs list -o mountpoint,compressratio,refcompressratio,used,available,usedbydataset,usedbysnapshots  -t filesystem

zfs list -o mountpoint,compressratio,refcompressratio,used,available,usedbydataset,usedbysnapshots -p -H  -t filesystem # NB: used includes all decendents

