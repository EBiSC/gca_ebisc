#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use ReseqTrack::EBiSC::hESCreg;
use Search::Elasticsearch;
use utf8;

my ($hESCreg_user, $hESCreg_pass);
my $es_host='vg-rs-dev1:9200';

GetOptions("user=s" => \$hESCreg_user,
    "pass=s" => \$hESCreg_pass,
    'es_host=s' =>\$es_host,
);
die "missing credentials" if !$hESCreg_user || !$hESCreg_pass;
my $elasticsearch = Search::Elasticsearch->new(nodes => $es_host);

eval{$elasticsearch->indices->delete(index => 'hescreg');};
$elasticsearch->indices->create(index => 'hescreg');
$elasticsearch->indices->put_mapping(
  index => 'hescreg',
  type => 'line',
  body => {
    line => {
      properties => {
        id => {type => 'integer'},
        name => {type => 'string', index => 'not_analyzed'},
        alternate_name => {type => 'string', index => 'not_analyzed'},
        biosamples_id => {type => 'string', index => 'not_analyzed'},
        donor_biosamples_id => {type => 'string', index => 'not_analyzed'},
      }
    }
  }
);

my $hESCreg = ReseqTrack::EBiSC::hESCreg->new(
  user => $hESCreg_user,
  pass => $hESCreg_pass,
  host => 'test.hescreg.eu',
  realm => 'hESCreg Development'
);

LINE:
foreach my $id (1..2000) {
  my $line = eval{$hESCreg->get_line($id);};
  next LINE if !$line || $@;
  $elasticsearch->index(
    index => 'hescreg',
    type => 'line',
    id => $id,
    body => $line,
    );
}
