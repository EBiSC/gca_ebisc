#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use ReseqTrack::EBiSC::hESCreg;
use JSON qw(encode_json);
use Data::Dumper;

my ($hESCreg_user, $hESCreg_pass, $jsonoutfile);

GetOptions("user=s" => \$hESCreg_user,
    "pass=s" => \$hESCreg_pass,
    "jsonoutfile=s" => \$jsonoutfile,
);
die "missing credentials" if !$hESCreg_user || !$hESCreg_pass;

my %output;

my $hESCreg = ReseqTrack::EBiSC::hESCreg->new(
  user => $hESCreg_user,
  pass => $hESCreg_pass,
);
LINE:
foreach my $line_name (@{$hESCreg->find_lines()}) {
  my $line = eval{$hESCreg->get_line($line_name);};
  next LINE if !$line || $@;
  $output{$line_name} = $line;
}

if ($jsonoutfile){
  my $json_out = encode_json(\%output);
  open(my $fh, '>', $jsonoutfile);
  print $fh $json_out; 
  close $fh;
}else{
  print Dumper \%output;
}

