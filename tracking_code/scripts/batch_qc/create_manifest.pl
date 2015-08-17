#!/usr/bin/env perl

use strict;
use warnings;
use File::Find qw();
use File::stat;
use File::Copy;
use File::Path qw();
use POSIX qw(strftime);
use Digest::MD5::File qw(file_md5_hex);
my $date = strftime('%Y%m%d', localtime);

my $drop_base = '/nfs/production/reseq-info/drop/ebisc-data';
my $incoming_dir = $drop_base.'/incoming';
my $manifest_dir = $drop_base.'/manifests';
my $cache_base = "$drop_base/cache";
my $dated_cache_base = "$drop_base/cache/$date";
my $current_manifest = $manifest_dir.'/manifests.current.tsv';
my $output_manifest = "$manifest_dir/manifests.$date.tsv";

my @error_log;

my %old_files;
my $num_old_files = 0;
open my $IN, '<', $current_manifest or die "could not open $current_manifest $!";
<$IN>;
while (my $line = <$IN>) {
  chomp $line;
  my ($path, $inode, $mtime, $md5, $size, $cache_path) = split("\t", $line);
  $old_files{$inode} = [$path, $mtime, $md5, $size, $cache_path];
  $num_old_files += 1;
}
close $IN;

my %new_files;
my $have_new;
File::Find::find(sub {
  return if -d $_;
  my $path = $File::Find::name;
  $path =~ s{$drop_base}{};
  my $st = stat($_);
  if (my $old_file = $old_files{$st->ino}) {
    my ($old_path, $old_mtime, $old_md5, $old_size, $old_cache_path) = @$old_file;
    if ($old_mtime eq $st->mtime) {
      if ($old_path eq $path) {
        $num_old_files -=1;
      }
      $new_files{$st->ino} = [$path, $st->mtime, $old_md5, $old_size, $old_cache_path];
      return;
    }
  }
  my $md5 = file_md5_hex($_);
  my $size = -s $_;
  my $cache_path = $File::Find::name;
  $cache_path =~ s{$incoming_dir}{$dated_cache_base};
  my $cache_dir = File::Basename::dirname($cache_path);
  File::Path::make_path($cache_dir, {mode => 0750});
  File::Copy::copy($_, $cache_path);
  $cache_path =~ s{$cache_base}{};
  $new_files{$st->ino} = [$path, $st->mtime, $md5, $size, $cache_path];
  $have_new = 1;
  return;
}, $incoming_dir);

if (! $have_new && ! $num_old_files) {
  exit;
}

open my $OUT, '>', $output_manifest or die "could not open $output_manifest $!";
print $OUT join("\t", qw(path inode mtime md5 size cache_path )), "\n";
foreach my $inode (sort keys %new_files) {
  my $file = $new_files{$inode};
  print $OUT join("\t", $file->[0], $inode, map {$file->[$_]} (1..4)), "\n";
}
close $OUT;

unlink($current_manifest);
File::Copy::copy($output_manifest, $current_manifest);
