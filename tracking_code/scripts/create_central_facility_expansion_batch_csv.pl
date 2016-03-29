#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw(decode_json);
use ReseqTrack::EBiSC::IMS;
use ReseqTrack::EBiSC::XMLUtils qw(dump_xml);
use ReseqTrack::EBiSC::BioSampleUtils;
use Data::Dumper;

my ($IMS_user, $IMS_pass);

GetOptions("ims_user=s" => \$IMS_user,
    "ims_pass=s" => \$IMS_pass,
);
die "missing credentials" if !$IMS_user || !$IMS_pass;

my $IMS = ReseqTrack::EBiSC::IMS->new(
  user => $IMS_user,
  pass => $IMS_pass,
);

my @batches;
foreach my $sample (@{$IMS->find_lines->{'objects'}}){
  if (defined $$sample{batches}){
    foreach my $batch (@{$sample->{batches}}){
      my $csvbatch = {};
      $csvbatch = {
      depositors_name => join('; ', @{$sample->{alternative_names}}), #TODO Get correct delimter from Maja
      hescreg_name => $sample->{name},
      ecacc_number => $sample->{ecacc_cat_no},
      name => $batch->{batch_id},
      batch_id => $batch->{biosamples_id},
      vial => [map { {vial_id => $_->{biosamples_id}, vial_number => $_->{number} }} @{$batch->{vials}}]
      };
      push(@batches, $csvbatch);
    }
  }
}
foreach my $batch (@batches){
  #TODO Run checks on existing files?
  #TODO Create csv output file
  print "Depositors Cell Line Name,hESCreg  Name,ECACC Cat no,Batch,Biosamples Batch ID,Vial number,Biosamples Vial ID\n";
  foreach my $vial (@{$batch->{vial}}) {
    print join(',', $$batch{depositors_name}, $$batch{hescreg_name}, $$batch{ecacc_number}, $$batch{name}, $$batch{batch_id}, $$vial{vial_number}, $$vial{vial_id}), "\n";
  }
}
