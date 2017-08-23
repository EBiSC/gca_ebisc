#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use XML::Simple;
use Data::Dumper;

my $xmlinfile;
GetOptions("xmlinfile=s" => \$xmlinfile);
die "missing json xmlinfile" if !$xmlinfile;

my $xml_data;
my $xml = new XML::Simple;
$xml_data = $xml->XMLin($xmlinfile,forcearray => 1);

my %observed_fields;
for (@{ $xml_data->{'CellLine'}}) {
  my $cellLine = $_;
  for my $key (keys(%{$cellLine})){
    $observed_fields{$key} = $$cellLine{$key};
  }
}

for my $key (keys(%observed_fields)){
  print $key, "\t", $observed_fields{$key}[0],"\n";
}