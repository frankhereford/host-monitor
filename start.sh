#!/bin/bash
echo Running infinite monitoring loop
while true
do
	new_cpu.pl
  traffic.pl
	cpu.pl
 	mem.pl
  traf.pl
	sleep 2
  #date
done
