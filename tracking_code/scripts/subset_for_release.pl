#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw();

my ($api_compares_json);
my %allowed_lines;

GetOptions("api_compares_json=s" => \$api_compares_json,
      "allowed_line=s" => sub {my ($name, $val) = @_; $allowed_lines{$val} = 1; },
);

open my $IN, '<', $api_compares_json or die "could not open $api_compares_json $!";
my @lines = <$IN>;
close $IN;
my $api_compares = JSON::decode_json(join('', @lines));

my @subset_lines = @_;
LINE:
foreach my $line_hash (@{$api_compares->{lines}}) {
  next LINE if !$allowed_lines{$line_hash->{consensus}{name}{val}};
  push(@subset_lines, $line_hash);
}
$api_compares->{lines} = \@subset_lines;
$api_compares->{count} = scalar @subset_lines;
print JSON::encode_json($api_compares);
