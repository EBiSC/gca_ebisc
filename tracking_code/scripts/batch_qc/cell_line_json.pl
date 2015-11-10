#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw();
use File::Path qw();
use JSON;
use POSIX qw(strftime);
use List::Util qw(max);
my $date = strftime('%Y%m%d', localtime);

my $track_base = '/nfs/production/reseq-info/work/ebiscdcc/api_tracking';
my $manifest = $track_base.'/manifests/manifests.current.tsv';
my $cache_base = $track_base.'/cache';
my $json_output = "$track_base/json/batches.$date.json";
my $current_json_output = "$track_base/json/batches.current.json";

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
  9 =>['culture_conditions/medium', {1 => 'Essential E8', 2 => 'mTeSTR'}],
  10 => ['culture_conditions/matrix', {1 => 'Vitronectin', 2 => 'Matrigel / Geltrex', 3 => 'Laminin'}],
  11 =>['culture_conditions/passage_method', {1 => 'EDTA', 2 => 'Manual Passaging'}],
  12 =>['culture_conditions/CO2_concentration', {1 =>'5%', free_text => 1}],
  13 =>['culture_conditions/O2_concentration', {1 => '21%', free_text => 1}],
  14 =>['culture_conditions/temperature', {1 => '37C', free_text => 1}],
  #15 =>['additional_comments', {1 => 'Typical recovery after thaw, typical growth cycle', free_text => 1}],
  16 =>['flag_go_live'],
);


my %cache_files;
my %cache_md5s;
open my $fh, '<', $manifest or die "could not open $manifest $!";
<$fh>;
while (my $line = <$fh>) {
  chomp $line;
  my @split_line = split("\t", $line);
  $cache_files{$split_line[0]} = \@split_line;
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
my $batch_qc_cache_file = $cache_files{$batch_qc_file}->[5];
$batch_qc_cache_file = "$cache_base/$batch_qc_cache_file";
open $fh, '<', $batch_qc_cache_file or die "could not open ".$batch_qc_cache_file." $!";
<$fh>;
LINE:
while (my $line = <$fh>) {
  chomp $line;
  my @split_line = map {clean_column($_)} split("\t", $line);
  my $name = $split_line[0];
  next LINE if !$name;
  my $batch_id = $split_line[1];
  next LINE if !$batch_id;
  my %batch;
  COLUMN:
  while (my ($column, $json_key) = each %column_map) {
    my $val = $split_line[$column];
    next COLUMN if ! defined $val;
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
my $images_cache_file = $cache_files{$images_file}->[5];
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
  my ($incoming_file) = grep {$_ =~ m{/(?:\d{8}[ _]+)?$file(?:\.[a-z]+)?$}} keys %cache_files;
  next IMAGE if !$incoming_file;
  my $cache_file = $cache_files{$incoming_file}->[5];
  if (grep {$_ eq $cache_file} @used_images) {
    die "image file used mored than once: $cache_file";
  }
  push(@{$batch->{images}}, {
    file => $cache_file,
    magnification => $magnification,
    timepoint => $timepoint,
    md5 => $cache_md5s{$cache_file},
    filename => File::Basename::fileparse($incoming_file),
    inode => $cache_files{$incoming_file}->[1],
    mtime => $cache_files{$incoming_file}->[2],
  });
  push(@used_images, $cache_file);
}
close $fh;


my %coas;
FILE:
foreach my $incoming_file ( grep {$_ =~ m{/incoming/wp5/certificate_of_analysis/}} keys %cache_files) {
  my $filename = File::Basename::fileparse($incoming_file);
  my $cache_file = $cache_files{$incoming_file}->[5];
  my ($cell_line, $batch) = split(/\./, $filename);
  $coas{$cell_line}{$batch} = {
    file => $cache_file,
    md5 => $cache_md5s{$cache_file},
    filename => $filename,
    inode => $cache_files{$incoming_file}->[1],
    mtime => $cache_files{$incoming_file}->[2],
  };
}
while (my ($cell_line, $cell_line_hash) = each %cell_lines) {
  BATCH:
  while (my ($batch, $batch_hash) = each %$cell_line_hash) {
    next BATCH if !$coas{$cell_line}{$batch};
    $batch_hash->{certificate_of_analysis} = $coas{$cell_line}{$batch};
  }
}

my %auas;
FILE:
foreach my $incoming_file ( grep {$_ =~ m{/incoming/wp5/access_use_agreements/}} keys %cache_files) {
  my $filename = File::Basename::fileparse($incoming_file);
  my $cache_file = $cache_files{$incoming_file}->[5];
  my ($cell_line, $type, $version) = split(/\./, $filename);
  $auas{$cell_line}{$type}{$version} = {
    file => $cache_file,
    md5 => $cache_md5s{$cache_file},
    filename => $filename,
    inode => $cache_files{$incoming_file}->[1],
    mtime => $cache_files{$incoming_file}->[2],
  };
}
CELL_LINE:
while (my ($cell_line, $cell_line_hash) = each %cell_lines) {
  next CELL_LINE if !$auas{$cell_line};
  TYPE:
  foreach my $type (qw(eAUA prAUA)) {
    next TYPE if !$auas{$cell_line}{$type};
    my $version = List::Util::max keys %{$auas{$cell_line}{$type}};
    my $key = $type == 'prAUA' ? 'pr_aua' : 'e_aua';
    BATCH:
    while (my ($batch, $batch_hash) = each %$cell_line_hash) {
      $batch_hash->{$key} = $auas{$cell_line}{$type}{$version};
    }
  }
}

open my $OUT, '>', $json_output or die "could not open $json_output $!";
print $OUT encode_json(\%cell_lines);
close $OUT;

UNLINK:
foreach (1..5) {
  last UNLINK if ! -e $current_json_output;
  unlink $current_json_output;
  sleep (1);
}
symlink($json_output, $current_json_output) or die $!;



sub clean_column {
  my ($val) = @_;
  return if ! defined $val;
  $val =~ s/^"(.*)"$/$1/;
  $val =~ s/^\s+//;
  $val =~ s/\s+$//;
  return $val;
}
