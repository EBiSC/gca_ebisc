#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use ReseqTrack::EBiSC::IMS;
use Data::Dumper;

my ($IMS_user, $IMS_pass);

GetOptions("user=s" => \$IMS_user,
    "pass=s" => \$IMS_pass,
);
die "missing credentials" if !$IMS_user || !$IMS_pass;

my %output;

my $IMS = ReseqTrack::EBiSC::IMS->new(
  user => $IMS_user,
  pass => $IMS_pass,
);
print Dumper $IMS->find_lines();
