#!/usr/bin/perl

use strict;
use RRDTool::OO;
use Number::Bytes::Human qw(format_bytes parse_bytes);
use Data::Dumper;


my $cmd = "zpool get -pH size,free,freeing,capacity,fragmentation";
open(my $zpool, "-|", $cmd);
my %zpool;
while (my $line = <$zpool>)
  {
  chomp $line;
  my @data = split(/\s/, $line);
  $data[2] =~ s/\%//g;
  $zpool{$data[1]} = $data[2];
  }
close $zpool;
#print Dumper \%zpool, "\n";


my $cmd = "zfs list -o mountpoint,compressratio,refcompressratio,used,available,usedbydataset,usedbysnapshots -p -t filesystem";
open(my $zfs, "-|", $cmd);
my %zfs;
my $headers = <$zfs>;
chomp $headers;
my @headers = split(/\s+/, $headers);
for (my $x = 0; $x < scalar(@headers); $x++)
  {
  $headers[$x] = lc($headers[$x]);
  }
#print Dumper \@headers, "\n";
while (my $line = <$zfs>)
  {
  chomp $line;
  my @data = split(/\s+/, $line);
  $zfs{$data[0]} = {};
  for (my $x = 1; $x < scalar(@data); $x++)
    {
    $zfs{$data[0]}->{$headers[$x]} = $data[$x];
    }
  }
close $zfs;
#print Dumper \%zfs, "\n";

my $totalsnap = 0;
foreach my $filesystem (keys(%zfs))
  {
  $totalsnap += $zfs{$filesystem}->{'usedsnap'};
  }
print format_bytes($totalsnap), " <= total snap used.\n";


my $used_data_set = 0;
foreach my $filesystem (keys(%zfs))
  {
  $used_data_set += $zfs{$filesystem}->{'usedds'};
  }
print format_bytes($used_data_set), " <= total data set.\n";