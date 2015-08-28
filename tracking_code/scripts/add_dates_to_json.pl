#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use JSON qw();
use List::Util qw();

my ($new_api_compares_json, $old_api_compares_json);

GetOptions("new_api_compares_json=s" => \$new_api_compares_json,
        "old_api_compares_json=s" => \$old_api_compares_json,
);

my ($IN, @lines);
open $IN, '<', $new_api_compares_json or die "could not open $new_api_compares_json $!";
@lines = <$IN>;
close $IN;
my $new_api_compares = JSON::decode_json(join('', @lines));
close $IN;

open $IN, '<', $old_api_compares_json or die "could not open $old_api_compares_json $!";
@lines = <$IN>;
close $IN;
my $old_api_compares = JSON::decode_json(join('', @lines));
close $IN;

my $date = $new_api_compares->{'date'} or die "could not extract date";
$date =~ s/ \d\d:\d\d:\d\d//;

CELL_LINE:
foreach my $cell_line (@{$new_api_compares->{'lines'}}) {
  my $old_cell_line = List::Util::first {$_->{'consensus'}{'name'}{'val'} eq $cell_line->{'consensus'}{'name'}{'val'}} @{$old_api_compares->{'lines'}};
  $old_cell_line ||= List::Util::first {$_->{'consensus'}{'biosample_id'}{'val'} eq $cell_line->{'consensus'}{'biosample_id'}{'val'}} @{$old_api_compares->{'lines'}};

  add_date($cell_line->{'IMS'}{'biosample_id'}, $old_cell_line->{'IMS'}{'biosample_id'});
  add_date($cell_line->{'IMS'}{'donor_biosample_id'}, $old_cell_line->{'IMS'}{'donor_biosample_id'});
  add_date($cell_line->{'IMS'}{'name'}, $old_cell_line->{'IMS'}{'name'});
  add_date($cell_line->{'biosample'}{'id'}, $old_cell_line->{'biosample'}{'id'});
  add_date($cell_line->{'consensus'}{'biosample_id'}, $old_cell_line->{'consensus'}{'biosample_id'});
  add_date($cell_line->{'consensus'}{'donor_biosample'}, $old_cell_line->{'consensus'}{'donor_biosample_id'});
  add_date($cell_line->{'consensus'}{'name'}, $old_cell_line->{'consensus'}{'name'});
  add_date($cell_line->{'hESCreg'}{'biosample_id'}, $old_cell_line->{'hESCreg'}{'biosample_id'});
  add_date($cell_line->{'hESCreg'}{'donor_biosample_id'}, $old_cell_line->{'hESCreg'}{'donor_biosample_id'});
  add_date($cell_line->{'hESCreg'}{'name'}, $old_cell_line->{'hESCreg'}{'name'});
  add_date($cell_line->{'IMS'}{'exported'}, $old_cell_line->{'IMS'}{'exported'});
  add_date($cell_line->{'biosample'}{'exported'}, $old_cell_line->{'biosample'}{'exported'});
  add_date($cell_line->{'hESCreg'}{'exported'}, $old_cell_line->{'hESCreg'}{'exported'});
  add_date($cell_line->{'hESCreg'}{'validated'}, $old_cell_line->{'hESCreg'}{'validated'});
  add_date($cell_line->{'donor_biosample'}, $old_cell_line->{'donor_biosample'};
};

print JSON::encode_json($new_api_compares);

sub add_date {
  my ($new_data, $old_data) = @_;
  return if !$new_data;
  return if !$new_data->{'error'};
  $new_data->{'error_date'} = !ref($old_data) ? $date : $old_data->{'error_date'} || $date;
}
