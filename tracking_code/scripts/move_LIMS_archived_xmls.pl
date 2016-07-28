#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use File::Find;
use File::Copy;
use File::Basename;
use POSIX qw(strftime);

my ($cellline_xml_folder, $cellline_xml_archive , $celline_ARK_fromLIMS);

GetOptions(
    "cellline_xml_folder=s" => \$cellline_xml_folder,
    "cellline_xml_archive=s" => \$cellline_xml_archive,
    "celline_ARK_fromLIMS=s" => \$celline_ARK_fromLIMS,
);

die "missing cellline folders" if !$cellline_xml_folder || !$cellline_xml_archive || !$celline_ARK_fromLIMS;

#Ensure that the XML archive folder has a folder for the present year
my $year = strftime('%Y', localtime);
my $fullarchivepath = $cellline_xml_archive.$year;
if (!-d $fullarchivepath) {
  my @args = ("mkdir", "$fullarchivepath");
  system(@args) == 0 or die "system @args failed: $?";
}

my %ARKfiles;
#Find base filenames without extensions for ARK files
find({ wanted => \&findARKfiles, no_chdir=>1}, $celline_ARK_fromLIMS);

my @XMLfiles;
#Find XML files in all subdirectories
find({ wanted => \&findXMLfiles, no_chdir=>1}, $cellline_xml_folder);

foreach(@XMLfiles){
  my $xmlfile = $_;
  my $base = basename($xmlfile);
  $base =~ s/\.xml$//;
  if (exists $ARKfiles{$base}){  # Check whether XML file has corresponding ARK file
    my $newloc_xmlfile = $xmlfile;
    $newloc_xmlfile =~ s/$cellline_xml_folder/$cellline_xml_archive/;
    move($xmlfile, $newloc_xmlfile) or die "Unable to move: $!";  # Move XML files to archive folder
  }
}

sub findARKfiles {
  my $F = $File::Find::name;
  my $ext = '\.ARK';
  if ($F =~ /$ext$/ ) {
    my $ARKfilename = basename($F);
    $ARKfilename =~ s/$ext$//;
    $ARKfiles{$ARKfilename}="";
  } 
  return;
}

sub findXMLfiles {
  my $F = $File::Find::name;
  if ($F =~ /\.xml$/ ){
    push @XMLfiles, $F;
  } 
  return;
}
