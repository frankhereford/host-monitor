#!/usr/bin/perl

use strict;
use RRDTool::OO;
use Tie::DNS;
use Data::Dumper;
use Number::Bytes::Human qw(format_bytes parse_bytes);

use DBI;
my $db = DBI->connect("DBI:mysql:database=dns;host=10.10.10.1", "docker");
my $device_sql = "select INET_NTOA(ip) as ip, hostname, dsname, rrd_graph_color from hosts where record_type = 'A' and no_rrd = 0 order by ip asc";
my $query = $db->prepare($device_sql);

tie my %dns, 'Tie::DNS';
my $human = Number::Bytes::Human->new(bs => 1000, round_style => 'round', precision => 2);

my $out = '/usr/sbin/iptaccount -l loc-net';
my $in = '/usr/sbin/iptaccount -l net-loc';

my $debug = 1;

my $operational_path = '/var/www/html'; # docker should be telling me this..
my $rrd_location = $operational_path . '/' . 'traffic.rrd';

my %network;
my @rrd_ds;
my @archives;
$query->execute();
while (my $host = $query->fetchrow_hashref)
  {
  $network{$host->{'ip'}} = {ip => $host->{'ip'}, host => $host->{'hostname'}};
  push(@rrd_ds, 'data_source' => {name => $host->{'dsname'} . 'rx', type => 'COUNTER'});
  push(@rrd_ds, 'data_source' => {name => $host->{'dsname'} . 'tx', type => 'COUNTER'});
  push(@archives, 'archive' => {rows => 24 * 60 * 60});
  push(@archives, 'archive' => {rows => 24 * 60 * 60});
  }

my $rrd = RRDTool::OO->new(file => $rrd_location);
if (!-e $rrd_location)
  {
  $rrd->create(
    step  => 5,
    @rrd_ds,
    @archives,
    );
  }

  my %traffic = ();

  open(my $data, "-|", "$out");
	while (my $line = <$data>)
	  {
	  chomp $line;
	  next if $line =~ /^showing/i;
	  next if $line =~ /^run/i;
	  next if $line =~ /^finished/i;
	  next if $line =~ /^libxt_account_cl/i;
	  next if $line =~ /^\s*$/;
    $line =~ /^ip: (\d+\.\d+\.\d+\.\d+) src packets: (\d+) bytes: (\d+)/i;
	  my $ip = $1;
	  my $src_packets = $2;
	  my $bytes = $3;
    $traffic{$ip} = {} unless defined($traffic{$ip});
    $traffic{$ip}->{'out'} = $bytes;
	  }

  open(my $data, "-|", "$in");
  while (my $line = <$data>)
    {
    chomp $line;
    next if $line =~ /^showing/i;
    next if $line =~ /^run/i;
    next if $line =~ /^finished/i;
    next if $line =~ /^libxt_account_cl/i;
    next if $line =~ /^\s*$/;
    $line =~ /^ip: (\d+\.\d+\.\d+\.\d+) src packets: \d+ bytes: \d+ dst packets: (\d+) bytes: (\d+)/i;
    my $ip = $1;
    my $dst_packets = $2;
    my $bytes = $3;
    $traffic{$ip} = {} unless defined($traffic{$ip});
    $traffic{$ip}->{'in'} = $bytes;
    }

  foreach my $host (keys(%traffic))
    {
    $traffic{$host}->{'in'} = 0 unless $traffic{$host}->{'in'};
    $traffic{$host}->{'out'} = 0 unless $traffic{$host}->{'out'};
    }

  my @updates;
  $query->execute();
  while (my $host = $query->fetchrow_hashref)
    {
    push(@updates, ($host->{'dsname'} . 'rx') => $traffic{$host->{'ip'}}->{'in'} ? $traffic{$host->{'ip'}}->{'in'} : 0);
    push(@updates, ($host->{'dsname'} . 'tx') => $traffic{$host->{'ip'}}->{'out'} ?  $traffic{$host->{'ip'}}->{'out'} : 0);
    }

  $rrd->update(time => time, values => { @updates });

  my @tx_draws;
  my @hidden_rx_draws;
  my @rx_draws;
  
  $query->execute();
  while (my $host = $query->fetchrow_hashref)
    {
    my $color = $host->{'rrd_graph_color'} || &hex_color;
    push @tx_draws,  (draw => { 
                              dsname => $host->{'dsname'} . 'tx',
                              type => 'area',
                              stack => 1,
                              color => $color,
                              legend => $host->{'hostname'} . ' TX',
                              });
    push @hidden_rx_draws,  (draw => {
                              dsname => $host->{'dsname'} . 'rx',
                              type => 'hidden',
                              name => $host->{'dsname'} . 'h',
                              });
    push @rx_draws,   (draw =>{
                              type => 'area',
                              cdef => $host->{'dsname'} . 'h,-1,*',
                              stack => 1,
                              color => $color,
                              legend => $host->{hostname} . ' RX',
                              });
    }


  $rrd->graph(
    image => $operational_path . '/' . 'traffic.png',
    width => 1100,
    height => 500, 
    start  => time() - 2*3600,
    end    => time(),
    vertical_label  => 'Bandwidth By Device',
    hrule => { value => 0,
           color => "#000000",
             },
    @tx_draws,
    @hidden_rx_draws,
    @rx_draws,
    );

sub hex_color
  {
  return sprintf('%02x',int(rand(200))) . sprintf('%02x',int(rand(200))) . sprintf('%02x',int(rand(200)));
  }