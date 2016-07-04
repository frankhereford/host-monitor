#!/usr/bin/perl

use strict; # we're not savages here.
use RRDTool::OO;

my $debug = 0;

my $operational_path = '/var/www/html'; # docker should be telling me this..
my $rrd_location = $operational_path . '/' . 'new_cpu.rrd';

my $rrd = RRDTool::OO->new(file => $rrd_location);
if (!-e $rrd_location)
  {
  $rrd->create(
    step 	=> 15,
    data_source => { name => 'system', type => 'GAUGE', },
    data_source => { name => 'user', type => 'GAUGE', },
    data_source => { name => 'io', type => 'GAUGE', },
    data_source => { name => 'nice', type => 'GAUGE', },
    data_source => { name => 'irq', type => 'GAUGE', },
    data_source => { name => 'soft', type => 'GAUGE', },
    data_source => { name => 'idle', type => 'GAUGE', },
    archive 	=> { rows => 24 * 60 * 60 },
    archive 	=> { rows => 24 * 60 * 60 },
    archive 	=> { rows => 24 * 60 * 60 },
    archive 	=> { rows => 24 * 60 * 60 },
    archive 	=> { rows => 24 * 60 * 60 },
    archive 	=> { rows => 24 * 60 * 60 },
    archive 	=> { rows => 24 * 60 * 60 },
    );
  }

open(my $mpstat, '-|', 'mpstat 1 1 | head -n 4 | tail -n 1');
my $cpu_info = <$mpstat>;
close $mpstat;
chomp $cpu_info;
#      0      1        2    3          4      5      6       7       8        9
print "%usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle\n" if ($debug);
#print $cpu_info, "\n";
$cpu_info =~ /all\s*(.*)/;
my $cpu_data = $1;
print $cpu_data, "\n" if ($debug);
my @data = split(/\s+/,$cpu_data);

#use Data::Dumper; print Dumper \@data, "\n"; exit; 
print $data[2], "\n" if ($debug);
print $data[0], "\n" if ($debug);
print $data[3], "\n" if ($debug);
print $data[1], "\n" if ($debug);
print $data[4], "\n" if ($debug);
print $data[5], "\n" if ($debug);
print $data[9], "\n" if ($debug);




$rrd->update(time => time, values => [$data[2],$data[0],$data[3],$data[1],$data[4],$data[5],$data[9]]);

$rrd->graph(
  image          	=> $operational_path . "/" . "output.png",
  vertical_label 	=> 'Jupiter CPU Statistics',
  start          	=> time() - 2*3600,
  end            	=> time(),
  width		 	=> 1100,
  height	 	=> 400,
  upper_limit		=> 100,
  lower_limit		=> 0,
  rigid			=> undef,
  draw			=> {	thickness	=> 1,
				color		=> 'BF1100',
				type		=> 'area',
				dsname		=> 'user',
				legend		=> 'User',
                    	   },
  draw			=> {	thickness	=> 1,
				color		=> 'C85F10',
				type		=> 'area',
				stack		=> 1,
				dsname		=> 'system',
				legend		=> 'System',
                    	   },
   draw			=> {	thickness	=> 1,
				color		=> 'D2A822',
				type		=> 'area',
				stack		=> 1,
				dsname		=> 'io',
				legend		=> 'IO',
                    	   },
  draw			=> {	thickness	=> 1,
				color		=> 'CCDC35',
				type		=> 'area',
				stack		=> 1,
				dsname		=> 'nice',
				legend		=> 'Nice',
                    	   },
  draw			=> {	thickness	=> 1,
				color		=> 'A3E64A',
				type		=> 'area',
				stack		=> 1,
				dsname		=> 'irq',
				legend		=> 'IRQ',
                    	   },

  draw			=> {	thickness	=> 1,
				color		=> '83F061',
				type		=> 'area',
				stack		=> 1,
				dsname		=> 'soft',
				legend		=> 'Soft',
                    	   },
  draw			=> {	thickness	=> 1,
				color		=> '79F986',
				type		=> 'area',
				stack		=> 1,
				dsname		=> 'idle',
				legend		=> 'Idle',
                    	   },
  );
