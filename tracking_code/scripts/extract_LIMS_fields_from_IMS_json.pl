#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw(decode_json encode_json);
use ReseqTrack::EBiSC::IMS;
use ReseqTrack::EBiSC::hESCreg;
use Data::Dumper;
use XML::Writer;

#TODO add XML output to this code or create JSON2XML library and call it
#my ($IMS_user, $IMS_pass, $json_filename, $xmloutfile);
my ($IMS_user, $IMS_pass, $json_filename_in);

GetOptions("ims_user=s" => \$IMS_user,
    "ims_pass=s" => \$IMS_pass,
    "json_filename_in=s" => \$json_filename_in,
    #"xmloutfile=s" => \$xmloutfile,
);
die "missing credentials" if !$IMS_user || !$IMS_pass;
die "missing json filename" if !$json_filename_in;
#die "missing xml filename" if !$xmloutfile;

my $IMS = ReseqTrack::EBiSC::IMS->new(
  user => $IMS_user,
  pass => $IMS_pass,
);

#open(my $xmlfile, '>', $xmloutfile);
#my $writer = new XML::Writer(OUTPUT => $xmlfile);
#$writer->xmlDecl( 'UTF-8' );
#$writer->startTag( 'data' );

my $IMSfiltered->{'objects'} = [];
foreach my $sample (@{$IMS->find_lines(lims_fields => 1)->{'objects'}}){
  push($IMSfiltered->{'objects'}, $sample);
}

#$writer->endTag( );
#$writer->end( );
#close($xmlfile);

open(my $json_file, '>', $json_filename_in);
my $json_filtered_out = encode_json($IMSfiltered);
print $json_file $json_filtered_out; #Filtered JSON
close $json_file;


