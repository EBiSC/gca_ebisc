#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw(decode_json);
use ReseqTrack::EBiSC::IMS;
use ReseqTrack::EBiSC::XMLUtils qw(dump_xml);

my ($IMS_user, $IMS_pass);

GetOptions("ims_user=s" => \$IMS_user,
    "ims_pass=s" => \$IMS_pass,
);
die "missing credentials" if !$IMS_user || !$IMS_pass;

my $IMS = ReseqTrack::EBiSC::IMS->new(
  user => $IMS_user,
  pass => $IMS_pass,
);

my $IMSfiltered->{'cell_line'} = [];
foreach my $sample (@{$IMS->find_lines(lims_fields => 1)->{'objects'}}){
  push($IMSfiltered->{'cell_line'}, $sample);
}

dump_xml(*STDOUT, 'cell_lines', $IMSfiltered);
