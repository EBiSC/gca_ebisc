#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw(decode_json encode_json);
use ReseqTrack::EBiSC::XMLUtils qw(dump_xml);

my ($jsoninfile, $xmloutfile, $filewrapper, $elementwrapper);

GetOptions("jsoninfile=s" => \$jsoninfile,
  "xmloutfile=s" => \$xmloutfile,
  "filewrapper=s" => \$filewrapper,
  "elementwrapper=s" => \$elementwrapper,
);

die "missing json infilename" if !$jsoninfile;
die "missing xml outfilename" if !$xmloutfile;
die "missing -filewrapper e.g. cell_lines" if !$filewrapper;
die "missing -elementwrapper e.g. cell_line" if !$elementwrapper;

my $infile = do {
   open(my $json_fh, "<:encoding(UTF-8)", $jsoninfile)
      or die("Can't open \$file\": $!\n");
   local $/;
   <$json_fh>
  };

my $json_full = decode_json($infile);

my @json_keys = keys %$json_full;
if (scalar @json_keys >1) {
  die "json schema is not compatible for this script";
}
my %data = ($elementwrapper => $json_full->{$json_keys[0]});
open(my $xmlfile, '>', $xmloutfile);
dump_xml($xmlfile, $filewrapper, \%data);

close($xmlfile);
