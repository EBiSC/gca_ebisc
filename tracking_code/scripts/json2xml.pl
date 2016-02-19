#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw(decode_json encode_json);
use XML::Writer;

my ($jsoninfile, $xmloutfile, $filewrapper, $elementwrapper);

GetOptions("jsoninfile=s" => \$jsoninfile,
  "xmloutfile=s" => \$xmloutfile,
  "filewrapper=s" => \$filewrapper,
  "elementwrapper=s" => \$elementwrapper,
);

die "missing json infilename" if !$jsoninfile;
die "missing xml outfilename" if !$xmloutfile;
die "missing -filewrapper e.g. cell_lines" if !$filewrapper;
die "missing -elementwrapper e.g. cell_line" if !$elementwrapper;

my $infile = do {
   open(my $json_fh, "<:encoding(UTF-8)", $jsoninfile)
      or die("Can't open \$file\": $!\n");
   local $/;
   <$json_fh>
  };

my $json_full = decode_json($infile);

open(my $xmlfile, '>', $xmloutfile);
my $writer = new XML::Writer(
  OUTPUT => $xmlfile,
  DATA_INDENT => 4,
  CHECK_PRINT => 1,
  DATA_MODE   => 1,
);

$writer->xmlDecl( 'UTF-8' );
$writer->startTag( $filewrapper );

foreach my $sample (@{$json_full->{((keys($json_full))[0])}}){
  $writer->startTag( $elementwrapper );
  foreach my $field (sort keys $sample){
    if (ref($$sample{$field}) eq 'HASH'){
      $writer->startTag( $field );
      foreach my $subfield (sort keys $$sample{$field}){
        if (ref($$sample{$field}{$subfield}) eq 'HASH'){
          $writer->startTag( $subfield );
          foreach my $subsubfield (sort keys $$sample{$field}{$subfield}){
            if (ref($$sample{$field}{$subfield}{$subsubfield}) eq 'ARRAY'){
              foreach my $part (@{$$sample{$field}{$subfield}{$subsubfield}}){
                &print_element($subsubfield, $part)
              }
            }else{
              &print_element($subsubfield, $$sample{$field}{$subfield}{$subsubfield})
            }
          }
          $writer->endTag($subfield);
        }elsif (ref($$sample{$field}{$subfield}) eq 'ARRAY'){
          foreach my $part (@{$$sample{$field}{$subfield}}){
            &print_element($subfield, $part)
          }
        }else{
          &print_element($subfield, $$sample{$field}{$subfield})
        }
      }
      $writer->endTag($field);
    }elsif (ref($$sample{$field}) eq 'ARRAY'){
      foreach my $part (@{$$sample{$field}}){
        if (ref($part) eq 'HASH'){
          $writer->startTag( $field );
          foreach my $subfield (sort keys $part){
            &print_element($subfield, $$part{$subfield});
          }
          $writer->endTag( $field );
        }else{
          &print_element($field, $part)
        }
       }
    }else{
      &print_element($field, $$sample{$field})
    }
  }
  $writer->endTag( $elementwrapper );
}

$writer->endTag( $filewrapper );
$writer->end( );
close($xmlfile);

sub print_element{
  $writer->startTag( $_[0] );
  $writer->characters($_[1]);
  $writer->endTag( $_[0] );
}