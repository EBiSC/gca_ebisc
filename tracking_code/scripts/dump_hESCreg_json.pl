#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use ReseqTrack::EBiSC::hESCreg;
use Data::Dumper;

my ($hESCreg_user, $hESCreg_pass);

GetOptions("user=s" => \$hESCreg_user,
    "pass=s" => \$hESCreg_pass,
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
print Dumper \%output;
