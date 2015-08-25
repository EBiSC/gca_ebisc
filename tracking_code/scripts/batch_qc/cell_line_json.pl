#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw();
use File::Path qw();
use JSON;
use POSIX qw(strftime);
my $date = strftime('%Y%m%d', localtime);

my $drop_base = '/nfs/production/reseq-info/drop/ebisc-data';
my $manifest = $drop_base.'/manifests/manifests.current.tsv';
my $cache_base = $drop_base.'/cache';
my $json_output = "$drop_base/json/batches.$date.json";
my $current_json_output = "$drop_base/json/batches.current.json";

my %column_map = (
  0 => ['cell_line'],
  1 => ['batch_id'],
  2 => ['biosamples_batch_id'],
  3 => ['ecacc_cat_no'],
  4 => ['vials_at_roslin'],
  5 => ['vials_shipped_to_fraunhoffer'],
  6 => ['vials_shipped_to_ECACC'],
  #7 => ['passage_number'],
  #8 => ['cells_per_vial'],
  9 => ['culture_conditions/matrix', {1 => 'Vitronectin', 2 => 'Matrigel / Geltrex', 3 => 'Laminin'}],
  10 =>['culture_conditions/medium', {1 => 'Essential E8', 2 => 'mTeSTR'}],
  11 =>['culture_conditions/passage_method', {1 => 'EDTA', 2 => 'Manual Passaging'}],
  12 =>['culture_conditions/CO2_concentration', {1 =>'5%', free_text => 1}],
  13 =>['culture_conditions/O2_concentration', {1 => '21%', free_text => 1}],
  14 =>['culture_conditions/temperature', {1 => '37C', free_text => 1}],
  #15 =>['additional_comments', {1 => 'Typical recovery after thaw, typical growth cycle', free_text => 1}],
);


my %cache_files;
my %cache_md5s;
open my $fh, '<', $manifest or die "could not open $manifest $!";
<$fh>;
while (my $line = <$fh>) {
  chomp $line;
  my @split_line = split("\t", $line);
  $cache_files{$split_line[0]} = $split_line[5];
  $cache_md5s{$split_line[5]} = $split_line[3];
}
close $fh;

my %cell_lines;

my %batch_qc_files;
FILE:
foreach my $file ( keys %cache_files) {
  my $matches = $file =~ m{/incoming/wp5/batchqc/ebisc.batch_qc.(\d+).txt};
  next FILE if !$matches;
  $batch_qc_files{$1} = $file;
}
my ($batch_qc_file) = map {$batch_qc_files{$_}} sort {$b <=> $a} keys %batch_qc_files;
die "did not find batch qc file" if !$batch_qc_file;
my $batch_qc_cache_file = $cache_files{$batch_qc_file};
$batch_qc_cache_file = "$cache_base/$batch_qc_cache_file";
open $fh, '<', $batch_qc_cache_file or die "could not open ".$batch_qc_cache_file." $!";
<$fh>;
LINE:
while (my $line = <$fh>) {
  chomp $line;
  my @split_line = split("\t", $line);
  my $name = $split_line[0];
  next LINE if !$name;
  my $batch_id = $split_line[1];
  next LINE if !$batch_id;
  my %batch;
  while (my ($column, $json_key) = each %column_map) {
    my $val = $split_line[$column];
    $val =~ s/^"(.*)"$/$1/;
    if (ref($json_key->[1]) eq 'HASH') {
      if (my $converted_val = $json_key->[1]->{$val}) {
        $val = $converted_val;
      }
      else {
        $val = $json_key->[1]->{free_text} ? $val : '';
      }
    }
    my @split_path = split('/', $json_key->[0]);
    if (@split_path == 1) {
      $batch{$split_path[0]} = $val;
    }
    elsif (@split_path ==2) {
      $batch{$split_path[0]}{$split_path[1]} = $val;
    }
  }

  $cell_lines{$name}{$batch_id} = \%batch;
}
close $fh;


my %images_files;
FILE:
foreach my $file ( keys %cache_files) {
  my ($date) = $file =~ m{/incoming/wp5/cell_images/ebisc.images[\.a-zA-Z_]*[\._](\d{8}).txt};
  next FILE if !$date;
  $images_files{$date} = $file;
}
my ($images_file) = map {$images_files{$_}} sort {$b <=> $a} keys %images_files;
die "did not find images file" if !$images_file;
my $images_cache_file = $cache_files{$images_file};
my @used_images;
$images_cache_file = "$cache_base/$images_cache_file";
open $fh, '<', $images_cache_file or die "could not open ".$images_cache_file." $!";
<$fh>;
IMAGE:
while (my $line = <$fh>) {
  chomp $line;
  $line =~ s/[^[:ascii:]]//g;
  my ($name, $batch_id, $file, $magnification, $timepoint) = split("\t", $line);
  $magnification =~ s{^[\s"]+}{}g;
  $magnification =~ s{[\s"]+$}{}g;
  $timepoint =~ s{^[\s"]+}{}g;
  $timepoint =~ s{[\s"]+$}{}g;
  $file =~ s{^[\s"]+}{}g;
  $file =~ s{[\s"]+$}{}g;
  $batch_id =~ s{^[\s"]+}{}g;
  $batch_id =~ s{[\s"]+$}{}g;
  $name =~ s{^[\s"]+}{}g;
  $name =~ s{[\s"]+$}{}g;
  next IMAGE if !$cell_lines{$name};
  my $batch = $cell_lines{$name}{$batch_id};
  next IMAGE if !$batch;
  my ($cache_file) = grep {$_ =~ m{/(?:\d{8}[ _]+)?$file(?:\.[a-z]+)?$}} values %cache_files;
  next IMAGE if !$cache_file;
  if (grep {$_ eq $cache_file} @used_images) {
    die "image file used mored than once: $cache_file";
  }
  push(@{$batch->{images}}, {
    file => $cache_file,
    magnification => $magnification,
    timepoint => $timepoint,
    md5 => $cache_md5s{$cache_file},
  });
  push(@used_images, $cache_file);
}
close $fh;


my %coas;
FILE:
foreach my $file ( keys %cache_files) {
  next FILE if $file !~ m{/incoming/wp5/certificate_of_analysis/};
  my $filename = File::Basename::fileparse($file);
  my ($ecacc_id) = $filename =~ /cat no (\d+)/i;
  $coas{$ecacc_id} = {
    file => $cache_files{$file},
    md5 => $cache_md5s{$cache_files{$file}},
  };
}
foreach my $cell_line_hash (values %cell_lines) {
  BATCH:
  foreach my $batch_hash (values %$cell_line_hash) {
    next BATCH if !$batch_hash->{ecacc_cat_no};
    next BATCH if !$coas{$batch_hash->{ecacc_cat_no}};
    $batch_hash->{certificate_of_analysis} = $coas{$batch_hash->{ecacc_cat_no}};
  }
}

open my $OUT, '>', $json_output or die "could not open $json_output $!";
print $OUT encode_json(\%cell_lines);
close $OUT;

if (-e $current_json_output) {
  unlink $current_json_output;
}
symlink($json_output, $current_json_output) or die $!;
