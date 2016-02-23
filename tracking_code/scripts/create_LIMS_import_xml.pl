#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw(decode_json);
use ReseqTrack::EBiSC::IMS;
use ReseqTrack::EBiSC::XMLUtils qw(dump_xml);
use ReseqTrack::EBiSC::BioSampleUtils;

my ($IMS_user, $IMS_pass, $json_filename_in);

GetOptions("ims_user=s" => \$IMS_user,
    "ims_pass=s" => \$IMS_pass,
);
die "missing credentials" if !$IMS_user || !$IMS_pass;

my $IMS = ReseqTrack::EBiSC::IMS->new(
  user => $IMS_user,
  pass => $IMS_pass,
);

my $biosample_lines = ReseqTrack::EBiSC::BioSampleUtils::find_lines();

my $IMSfiltered->{'cell_line'} = [];
foreach my $sample (@{$IMS->find_lines(lims_fields => 1)->{'objects'}}){
  if (my $batches = $biosample_lines->{$sample->{name}}{batches}) {
    $has_batch += 1;
    my ($batch_id) = sort @$batches;
    my $batch = BioSD::fetch_group($batch_id);
    $sample->{batch} = {
      batch_id => $batch_id,
      vial => [map { {vial_id => $_->id, name => $_->property('Sample Name')->values->[0]} } @{$batch->samples}]
    }
  }
  push($IMSfiltered->{'cell_line'}, $sample);
}

dump_xml(*STDOUT, 'cell_lines', $IMSfiltered);
