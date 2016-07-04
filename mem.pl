#!/usr/bin/perl
#
# coded by Martin Pot 2003
# http://martybugs.net/smoothwall/rrdtool_mem.cgi
#
# SmoothWall scripts
#
# This code is distributed under the terms of the GPL
#
# (c) The SmoothWall Team
# rrdtool_mem.pl

# a little hacking by Frank Hereford to make this work with modern free on xenial


# define location of rrdtool binary

use strict;


my $rrdtool = '/usr/bin/rrdtool';
# define location of rrdtool databases
my $rrd = '/var/www/html';
# define location of images
my $img = '/var/www/html';

# get memory usage
my $mem = `free -g -w |grep Mem`;
my $swap = `free -g -w |grep Swap`;# |cut -c19-29 |sed 's/ //g'`;
my @mem = split(/\s+/, $mem);
my @swap = split(/\s+/, $swap);

#print "Mem: ", $mem;
#print "Swap: ", $swap;
#
#for (my $x = 0; $x < scalar(@mem); $x++)
  #{ print $x, ": ", $mem[$x], "\n"; }
#for (my $x = 0; $x < scalar(@swap); $x++)
  #{ print $x, ": ", $swap[$x], "\n"; }


# if rrdtool database doesn't exist, create it
if (! -e "$rrd/mem.rrd")
{
        print "creating rrd database for memory usage...\n";
        system("$rrdtool create $rrd/mem.rrd -s 300"
                ." DS:mem:GAUGE:600:0:U"
                ." DS:buf:GAUGE:600:0:U"
                ." DS:cache:GAUGE:600:0:U"
                ." DS:swap:GAUGE:600:0:U"
                ." RRA:AVERAGE:0.5:1:576"
                ." RRA:AVERAGE:0.5:6:672"
                ." RRA:AVERAGE:0.5:24:732"
                ." RRA:AVERAGE:0.5:144:1460");
}

# insert values into rrd
#print "$rrdtool update $rrd/mem.rrd -t mem:buf:cache:swap N:$mem[2]:$mem[5]:$mem[6]:$swap[2]\n";
`$rrdtool update $rrd/mem.rrd -t mem:buf:cache:swap N:$mem[2]:$mem[5]:$mem[6]:$swap[2]`;

# create graphs
&CreateGraph("day");
&CreateGraph("week");
&CreateGraph("month"); 
&CreateGraph("year");

sub CreateGraph
{
# creates graph
# inputs: $_[0]: interval (ie, day, week, month, year)

	system("$rrdtool graph $img/mem-$_[0].png"
		." -s \"-1$_[0]\""
		." -t \"memory usage over the last $_[0]\""
		." --lazy"
		." -h 150 -w 700"
		." -l 0"
		." -a PNG"
		." -v \"gigabytes\""
		." -b 1024"
		." DEF:mem=$rrd/mem.rrd:mem:AVERAGE"
		." DEF:buf=$rrd/mem.rrd:buf:AVERAGE"
		." DEF:cache=$rrd/mem.rrd:cache:AVERAGE"
		." DEF:swap=$rrd/mem.rrd:swap:AVERAGE"
		." CDEF:total=mem,swap,buf,cache,+,+,+"
		." CDEF:res=mem,buf,cache,+,+"
		." AREA:mem#FFCC66:\"Physical Memory Usage\""
		." STACK:buf#FF9999:\"Buffers\""
		." STACK:cache#FF0099:\"Cache\""
		." STACK:swap#FF9900:\"Swap Memory Usage\\n\""
		." GPRINT:mem:MAX:\"Residental  Max\\: %5.1lf %s\""
		." GPRINT:mem:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:mem:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:buf:MAX:\"Buffers     Max\\: %5.1lf %s\""
		." GPRINT:buf:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:buf:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:cache:MAX:\"Cache       Max\\: %5.1lf %s\""
		." GPRINT:cache:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:cache:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:swap:MAX:\"Swap        Max\\: %5.1lf %s\""
		." GPRINT:swap:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:swap:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:total:MAX:\"Total       Max\\: %5.1lf %s\""
		." GPRINT:total:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:total:LAST:\" Current\\: %5.1lf %s\\n\""
		." LINE1:res#CC9966"
		." LINE1:total#CC6600 > /dev/null");
}
