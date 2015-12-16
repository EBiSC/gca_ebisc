#!/usr/bin/env perl

use strict;
use warnings;
use JSON;
use POSIX qw(strftime);
use Data::Compare;
use File::Basename qw();
use File::Path qw();
use List::Util qw();
my $date = strftime('%Y%m%d', localtime);

my $track_base = '/nfs/production/reseq-info/work/ebiscdcc/api_tracking';
my $export_base = $track_base.'/export';
my $current_export_base = $export_base.'/current';
my $today_export_base = "$export_base/$date";
my $current_json_file = "$track_base/json/batches.current.json";
my $api_base = 'http://www.ebi.ac.uk/~ebiscdcc/api';
my $cache_base = $track_base.'/cache';

open my $IN, '<', $current_json_file or die "could not open $current_json_file $!";
my @lines = <$IN>;
my $today_cell_lines = decode_json(join('', @lines));
close $IN;

my %export_files;

my %batch_list = (
  links => {self => "$api_base/batch.json"},
  meta => {type => 'batch_list'},
  data => [],
);

while (my ($cell_line, $batches) = each %$today_cell_lines) {
  while (my ($batch_id, $batch_data) = each %$batches) {
    my $current_exported_json = "$current_export_base/batch/$cell_line/$batch_id.json";
    my $current_exported_batch = {data => {}, meta => {}};
    if (-f $current_exported_json) {
      open $IN, '<', $current_exported_json or die "could not open $current_exported_json";
      @lines = <$IN>;
      close $IN;
      $current_exported_batch = decode_json(join('', @lines));
    }

    if (my $coa = $batch_data->{certificate_of_analysis}) {
      my $from = $coa->{file};
      my $to = sprintf('file/%s/%s/%s', $coa->{inode}, $coa->{mtime}, $coa->{filename});
      $export_files{$from} = $to;
      $batch_data->{certificate_of_analysis}{file} = "$api_base/$to";
      if (my $current_coa = $current_exported_batch->{data}{certificate_of_analysis}) {
        if (File::Basename::fileparse($current_coa->{file}) eq File::Basename::fileparse($coa->{file}) && $current_coa->{md5} eq $coa->{md5}) {
          $coa->{updated} = $current_coa->{updated};
        }
      }
      $coa->{updated} ||= $date;
      delete @$coa{qw(filename inode mtime)};
    }

    if ($batch_data->{cell_line_information_packs}) {
      foreach my $clip (@{$batch_data->{cell_line_information_packs}}) {
        my $from = $clip->{file};
        my $to = sprintf('file/%s/%s/%s', $clip->{inode}, $clip->{mtime}, $clip->{filename});
        $export_files{$from} = $to;
        $clip->{file} = "$api_base/$to";
        my $version = $clip->{version};

        if (my $current_clip = List::Util::first { $_->{version} eq $version } @{$current_exported_batch->{data}{cell_line_information_packs}}) {
          if (File::Basename::fileparse($current_clip->{file}) eq File::Basename::fileparse($clip->{file}) && $current_clip->{md5} eq $clip->{md5}) {
            $clip->{updated} = $current_clip->{updated};
          }
        }
        $clip->{updated} ||= $date;
        delete @$clip{qw(filename inode mtime)};
      }
    }

    foreach my $aua_type (qw(e_aua pr_aua)) {
      if (my $aua = $batch_data->{$aua_type}) {
        my $from = $aua->{file};
        my $to = sprintf('file/%s/%s/%s', $aua->{inode}, $aua->{mtime}, $aua->{filename});
        $export_files{$from} = $to;
        $batch_data->{$aua_type}{file} = "$api_base/$to";
        if (my $current_aua = $current_exported_batch->{data}{$aua_type}) {
          if (File::Basename::fileparse($current_aua->{file}) eq File::Basename::fileparse($aua->{file}) && $current_aua->{md5} eq $aua->{md5}) {
            $aua->{updated} = $current_aua->{updated};
          }
        }
        $aua->{updated} ||= $date;
        delete @$aua{qw(filename inode mtime)};
      }
    }
    if ($batch_data->{images}) {
      foreach my $image (@{$batch_data->{images}}) {
        my $from = $image->{file};
        my $to = sprintf('file/%s/%s/%s', $image->{inode}, $image->{mtime}, $image->{filename});
        $export_files{$from} = $to;
        $image->{file} = "$api_base/$to";
        if ($current_exported_batch->{data}{images}) {
          my ($current_image) = grep {File::Basename::fileparse($_->{file}) eq File::Basename::fileparse($image->{file}) && $_->{md5} eq $image->{md5}} @{$current_exported_batch->{data}{images}};
          if ($current_image) {
            $image->{updated} = $current_image->{updated};
          }
        }
        $image->{updated} ||= $date;
        delete @$image{qw(filename inode mtime)};
      }
    }

    my $updated = Compare($current_exported_batch->{data}, $batch_data) ? $current_exported_batch->{meta}->{updated} : $date;
    my %export_json = (
      links => {
        self => "$api_base/batch/$cell_line/$batch_id.json",
      },
      data => $batch_data,
      meta => {
        type => 'batch',
        updated => $updated,
      }
    );
    push(@{$batch_list{data}}, {
      cell_line => $cell_line,
      batch_id => $batch_id,
      updated => $updated,
      href => "$api_base/batch/$cell_line/$batch_id.json",
    });

    my $output_file = "$today_export_base/batch/$cell_line/$batch_id.json";
    File::Path::make_path("$today_export_base/batch/$cell_line/");
    open my $OUT, '>', $output_file or die "could not open $output_file $!";
    print $OUT encode_json(\%export_json);
    close $OUT;
  }
}

my $output_file = "$today_export_base/batch.json";
File::Path::make_path($today_export_base);
open my $OUT, '>', $output_file or die "could not open $output_file $!";
print $OUT encode_json(\%batch_list);
close $OUT;


FILE:
while (my ($from, $to) = each %export_files) {
  my $from = "$cache_base/$from";
  my $to = "$today_export_base/$to";
  File::Path::make_path(File::Basename::dirname($to));
  next FILE if -e $to;
  symlink($from, $to) or die $!;
}

if (-e $current_export_base) {
  unlink $current_export_base;
}
symlink($today_export_base, $current_export_base) or die $!;
