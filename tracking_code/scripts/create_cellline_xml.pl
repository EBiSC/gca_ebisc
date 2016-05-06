#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw(encode_json decode_json);
use ReseqTrack::EBiSC::IMS;
use ReseqTrack::EBiSC::XMLUtils qw(dump_xml);
use Test::Deep::NoTest;
use POSIX qw(strftime);

my $date = strftime('%Y%m%d%H%M%S', localtime);

my ($IMS_user, $IMS_pass);
my $xmloutfile = '/nfs/production/reseq-info/drop/ebisc-data/outgoing/cellline_xml/cellline'.$date.'.xml';

my $cellsfile = '/nfs/production/reseq-info/work/ebiscdcc/lims_celline_update_check/validated_celllines_store.json';

GetOptions("ims_user=s" => \$IMS_user,
    "ims_pass=s" => \$IMS_pass,
    "xmloutfile=s" => \$xmloutfile,
    "cellsfile=s" => \$cellsfile,
);
die "missing credentials" if !$IMS_user || !$IMS_pass;

my $IMS = ReseqTrack::EBiSC::IMS->new(
  user => $IMS_user,
  pass => $IMS_pass,
);

open(my $arrayinfh, '<', $cellsfile) or die "Could not open file '$cellsfile' $!";
my @lines = <$arrayinfh>;
my $current_lines = decode_json(join('', @lines));
close($arrayinfh);

my %known_line_dict;
foreach my $known_line (@{$$current_lines{'cell_line'}}){
  $known_line_dict{$$known_line{name}} = $known_line;
}

my $IMSfiltered->{'cell_line'} = [];
my $IMSfiltered_updated->{'cell_line'} = [];
my $changecount = 0;
foreach my $sample (@{$IMS->find_lines(lims_fields => 1)->{'objects'}}){
  if (!(eq_deeply($sample, $known_line_dict{$$sample{name}}))){
    $changecount++;
    push($IMSfiltered_updated->{'cell_line'}, $sample);
  }
  push($IMSfiltered->{'cell_line'}, $sample);
}

open(my $xmlfh, '>', $xmloutfile) or die "Could not open file '$xmloutfile' $!";
dump_xml($xmlfh, 'cell_lines', $IMSfiltered_updated);
print $xmlfh '<!-- '.$date.' - There were '.$changecount.' new or altered cell line changes since the last file.->';
close($xmlfh);

open(my $arrayoutfh, '>', $cellsfile) or die "Could not open file '$cellsfile' $!";
print $arrayoutfh encode_json($IMSfiltered), "\n";
close($arrayoutfh);