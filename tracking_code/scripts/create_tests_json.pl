#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw();

my ($api_compares_json);

GetOptions("api_compares_json=s" => \$api_compares_json,
);

open my $IN, '<', $api_compares_json or die "could not open $api_compares_json $!";
my @lines = <$IN>;
close $IN;
my $api_compares = JSON::decode_json(join('', @lines));

my %tests_totalled;
my %tests;
LINE:
foreach my $cell_line (@{$api_compares->{lines}}) {
  my $has_a_fail;
  while (my ($key, $val) = each %{$cell_line->{tests}}) {
    $tests{$key}{$val} += 1;
    if ($val ne 'pass') {
      $has_a_fail = 1;
    }
  }
  $tests_totalled{$has_a_fail ? 'fail' : 'pass'} += 1;
}

print JSON::encode_json({tests => [map {{description => $_, %{$tests{$_}}}} sort{
      ($b =~ /^IMS/) <=> ($a =~ /^IMS/)
      || ($b =~ /^hPSC/) <=> ($a =~ /^hPSC/)
      || ($b =~ /^Bio/) <=> ($a =~ /^Bio/)
      || length($a) <=> length($b)
      || $a cmp $b
    }keys %tests],
    tests_totalled => \%tests_totalled,
    });
