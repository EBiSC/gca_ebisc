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

my %errors;
LINE:
foreach my $cell_line (@{$api_compares->{lines}}) {
  my @errors;
  if ($cell_line->{IMS}{exported}{error}) {
    push(@errors, 'Cell line is not exported by IMS');
  }
  else {
    push(@errors, grep {$_} map {$_->{error_string}} @{$cell_line->{IMS}}{qw(biosample_id donor_biosample_id name)});
  }

  if ($cell_line->{hESCreg}{exported}{error}) {
    push(@errors, 'Cell line is not exported by hESCreg');
  }
  else {
    push(@errors, grep {$_} map {$_->{error_string}} @{$cell_line->{hESCreg}}{qw(biosample_id donor_biosample_id name)});
  }

  if ($cell_line->{biosample}{exported}{error}) {
    push(@errors, 'Cell line is not exported by BioSamples');
  }
  else {
    push(@errors, grep {$_} map {$_->{error_string}} @{$cell_line->{biosample}}{qw(id batch_donor_link batch_line_link)});
  }

  if ($cell_line->{donor_biosample}) {
    if ($cell_line->{donor_biosample}{exported}{error}) {
      push(@errors, 'Donor is not exported by BioSamples');
    }
  }

  next LINE if !@errors;
  my $error_key = join('', sort @errors);
  $errors{$error_key} //= {errors => \@errors, lines =>[]};

  my $cell_line_name = $cell_line->{consensus}{name}{val} || $cell_line->{consensus}{biosample_id}{val};
  push(@{$errors{$error_key}{lines}}, $cell_line_name);
}

print JSON::encode_json({errors => [sort {scalar @{$b->{lines}} <=> scalar @{$a->{lines}}} values %errors]});
