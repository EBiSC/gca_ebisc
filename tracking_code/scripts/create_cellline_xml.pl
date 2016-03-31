#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw(decode_json);
use ReseqTrack::EBiSC::IMS;
use ReseqTrack::EBiSC::XMLUtils qw(dump_xml);

my ($IMS_user, $IMS_pass);
my $xmloutfile = '/nfs/production/reseq-info/drop/ebisc-data/outgoing/cellline_xml/cellline.xml';

GetOptions("ims_user=s" => \$IMS_user,
    "ims_pass=s" => \$IMS_pass,
    "xmloutfile=s" => \$xmloutfile,
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
open(my $fh, '>', $xmloutfile) or die "Could not open file '$xmloutfile' $!";
dump_xml($fh, 'cell_lines', $IMSfiltered);
close($fh);
