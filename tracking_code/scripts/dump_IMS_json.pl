#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use ReseqTrack::EBiSC::IMS;
use JSON qw(encode_json);
use Data::Dumper;

my ($IMS_user, $IMS_pass, $jsonoutfile);

GetOptions("user=s" => \$IMS_user,
    "pass=s" => \$IMS_pass,
    "jsonoutfile=s" => \$jsonoutfile,
);
die "missing credentials" if !$IMS_user || !$IMS_pass;

my %output;

my $IMS = ReseqTrack::EBiSC::IMS->new(
  user => $IMS_user,
  pass => $IMS_pass,
);

if ($jsonoutfile){
  my $json_out = encode_json($IMS->find_lines());
  open(my $fh, '>', $jsonoutfile);
  print $fh $json_out; 
  close $fh;
}else{
  print Dumper $IMS->find_lines();
}