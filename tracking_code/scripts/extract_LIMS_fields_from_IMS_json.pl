#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use JSON qw(decode_json encode_json);
use ReseqTrack::EBiSC::IMS;
use ReseqTrack::EBiSC::hESCreg;
use Data::Dumper;
use XML::Writer;

#TODO add XML output to this code or create JSON2XML library and call it
#my ($IMS_user, $IMS_pass, $json_filename, $xmloutfile);
my ($IMS_user, $IMS_pass, $json_filename_in);

GetOptions("ims_user=s" => \$IMS_user,
    "ims_pass=s" => \$IMS_pass,
    "json_filename_in=s" => \$json_filename_in,
    #"xmloutfile=s" => \$xmloutfile,
);
die "missing credentials" if !$IMS_user || !$IMS_pass;
die "missing json filename" if !$json_filename_in;
#die "missing xml filename" if !$xmloutfile;

my $IMS = ReseqTrack::EBiSC::IMS->new(
  user => $IMS_user,
  pass => $IMS_pass,
);

#open(my $xmlfile, '>', $xmloutfile);
#my $writer = new XML::Writer(OUTPUT => $xmlfile);
#$writer->xmlDecl( 'UTF-8' );
#$writer->startTag( 'data' );

my $IMSfiltered->{'objects'} = [];
foreach my $sample (@{$IMS->find_lines()->{'objects'}}){
  my $sample_index = {};

  if ($$sample{name}){$sample_index->{name} = $$sample{name};}
  if ($$sample{alternative_names}){$sample_index->{alternative_names} = $$sample{alternative_names};}
  if ($$sample{biosamples_id}){$sample_index->{biosamples_id} = $$sample{biosamples_id};}
  if ($$sample{ecacc_cat_no}){$sample_index->{ecacc_cat_no} = $$sample{ecacc_cat_no};}
  
  if ($$sample{primary_cell_type}{name}){$sample_index->{primary_cell_type}{name} = $$sample{primary_cell_type}{name};}

  if ($$sample{donor}{gender}){$sample_index->{donor}{gender} = $$sample{donor}{gender};}
  if ($$sample{donor}{biosamples_id}){$sample_index->{donor}{biosamples_id} = $$sample{donor}{biosamples_id};}
  if ($$sample{donor}{internal_donor_ids}){$sample_index->{donor}{internal_donor_ids} = $$sample{donor}{internal_donor_ids};}
  if ($$sample{donor}{disease_associated_phenotypes}){$sample_index->{donor}{disease_associated_phenotypes} = $$sample{donor}{disease_associated_phenotypes};}
  if ($$sample{donor}{phenotypes}){$sample_index->{donor}{phenotypes} = $$sample{donor}{phenotypes};}
  if ($$sample{donor}{karyotype}){$sample_index->{donor}{karyotype} = $$sample{donor}{karyotype};}

  if ($$sample{cellline_karyotype}{karyotype}){$sample_index->{cellline_karyotype} = $$sample{cellline_karyotype}{karyotype};}

  if ($$sample{reprogramming_method}{type}){$sample_index->{reprogramming_method}{type} = $$sample{reprogramming_method}{type};}
  if ($$sample{reprogramming_method}{data}{vector}){$sample_index->{reprogramming_method}{data}{vector} = $$sample{reprogramming_method}{data}{vector};}
  #TODO if ($$sample{reprogramming_method}{data}{vector_free_types}){$sample_index->{reprogramming_method}{data}{vector_free_types} = $$sample{reprogramming_method}{data}{vector_free_types};}
  if ($$sample{reprogramming_method}{data}{virus}){$sample_index->{reprogramming_method}{data}{virus} = $$sample{reprogramming_method}{data}{virus};}
  if ($$sample{reprogramming_method}{data}{transposon}){$sample_index->{reprogramming_method}{data}{transposon} = $$sample{reprogramming_method}{data}{transposon};}
  if ($$sample{reprogramming_method}{data}{non_integrating_vector_gene_list}){$sample_index->{reprogramming_method}{data}{non_integrating_vector_gene_list} = $$sample{reprogramming_method}{data}{non_integrating_vector_gene_list};}
  if ($$sample{reprogramming_method}{data}{integrating_vector_gene_list}){$sample_index->{reprogramming_method}{data}{integrating_vector_gene_list} = $$sample{reprogramming_method}{data}{integrating_vector_gene_list};}
  #TODO if ($$sample{reprogramming_method}{data}{non_integrating_detectable_flag}){$sample_index->{reprogramming_method}{data}{non_integrating_detectable_flag} = $$sample{reprogramming_method}{data}{non_integrating_detectable_flag};}
  #TODO if ($$sample{reprogramming_method}{data}{non_integrating_method}){$sample_index->{reprogramming_method}{data}{non_integrating_method} = $$sample{reprogramming_method}{data}{non_integrating_method};}
  #TODO if ($$sample{reprogramming_method}{data}{non_integrating_detection_notes}){$sample_index->{reprogramming_method}{data}{non_integrating_detection_notes} = $$sample{reprogramming_method}{data}{non_integrating_detection_notes};}
  #TODO if ($$sample{reprogramming_method}{data}{reprogramming_vector_non_integrating_detection_uploads}){$sample_index->{reprogramming_method}{data}{reprogramming_vector_non_integrating_detection_uploads} = $$sample{reprogramming_method}{data}{reprogramming_vector_non_integrating_detection_uploads};}
  #TODO if ($$sample{reprogramming_method}{data}{integrating_silenced_flag}){$sample_index->{reprogramming_method}{data}{integrating_silenced_flag} = $$sample{reprogramming_method}{data}{integrating_silenced_flag};}
  #TODO if ($$sample{reprogramming_method}{data}{integrating_method}){$sample_index->{reprogramming_method}{data}{integrating_method} = $$sample{reprogramming_method}{data}{integrating_method};}
  #TODO if ($$sample{reprogramming_method}{data}{integrating_silencing_notes}){$sample_index->{reprogramming_method}{data}{integrating_silencing_notes} = $$sample{reprogramming_method}{data}{integrating_silencing_notes};}
  #TODO if ($$sample{reprogramming_method}{data}{integrating_silencing_uploads}){$sample_index->{reprogramming_method}{data}{integrating_silencing_uploads} = $$sample{reprogramming_method}{data}{integrating_silencing_uploads};}


  if ($$sample{primary_disease_diagnosed}){$sample_index->{primary_disease_diagnosed} = $$sample{primary_disease_diagnosed};}
  if ($$sample{primary_disease}{name}){$sample_index->{primary_disease}{name} = $$sample{primary_disease}{name};}
  if ($$sample{disease_associated_phenotypes}){$sample_index->{disease_associated_phenotypes} = $$sample{disease_associated_phenotypes};}
  #TODO if ($$sample{carries_disease_phenotype_associated_variants_flag}){$sample_index->{carries_disease_phenotype_associated_variants_flag} = $$sample{carries_disease_phenotype_associated_variants_flag};}
  #TODO if ($$sample{variant_of_interest_flag}){$sample_index->{variant_of_interest_flag} = $$sample{variant_of_interest_flag};}

  if ($$sample{depositor_cellline_culture_conditions}{surface_coating}){$sample_index->{depositor_cellline_culture_conditions}{surface_coating} = $$sample{depositor_cellline_culture_conditions}{surface_coating};}
  if ($$sample{depositor_cellline_culture_conditions}{passage_method}){$sample_index->{depositor_cellline_culture_conditions}{passage_method} = $$sample{depositor_cellline_culture_conditions}{passage_method};}
  if ($$sample{depositor_cellline_culture_conditions}{o2_concentration}){$sample_index->{depositor_cellline_culture_conditions}{o2_concentration} = $$sample{depositor_cellline_culture_conditions}{o2_concentration};}
  if ($$sample{depositor_cellline_culture_conditions}{co2_concentration}){$sample_index->{depositor_cellline_culture_conditions}{co2_concentration} = $$sample{depositor_cellline_culture_conditions}{co2_concentration};}
  if ($$sample{depositor_cellline_culture_conditions}{feeder_cell_type}){$sample_index->{depositor_cellline_culture_conditions}{feeder_cell_type} = $$sample{depositor_cellline_culture_conditions}{feeder_cell_type};}

  if ($$sample{virology_screening}{virology_screening_flag}){$sample_index->{virology_screening}{virology_screening_flag} = $$sample{virology_screening}{virology_screening_flag};}
  if ($$sample{virology_screening}{hiv1}){$sample_index->{virology_screening}{hiv1} = $$sample{virology_screening}{hiv1};}
  if ($$sample{virology_screening}{hiv2}){$sample_index->{virology_screening}{hiv2} = $$sample{virology_screening}{hiv2};}
  if ($$sample{virology_screening}{hepatitis_b}){$sample_index->{virology_screening}{hepatitis_b} = $$sample{virology_screening}{hepatitis_b};}
  if ($$sample{virology_screening}{hepatitis_c}){$sample_index->{virology_screening}{hepatitis_c} = $$sample{virology_screening}{hepatitis_c};}

  if ($$sample{cellline_certificate_of_analysis}{certificate_of_analysis_flag}){$sample_index->{cellline_certificate_of_analysis}{certificate_of_analysis_flag} = $$sample{cellline_certificate_of_analysis}{certificate_of_analysis_flag};}

  if ($$sample{depositor_cellline_culture_conditions}{certificate_of_analysis_flag}){$sample_index->{depositor_cellline_culture_conditions}{culture_medium_supplements} = $$sample{depositor_cellline_culture_conditions}{culture_medium_supplements};}

  #TODO if ($$sample{rock_inhibitor_used_at_passage_flag}){$sample_index->{rock_inhibitor_used_at_passage_flag} = $$sample{rock_inhibitor_used_at_passage_flag};}
  #TODO if ($$sample{rock_inhibitor_used_at_cryo_flag}){$sample_index->{rock_inhibitor_used_at_cryo_flag} = $$sample{rock_inhibitor_used_at_cryo_flag};}
  #TODO if ($$sample{rock_inhibitor_used_at_thaw_flag}){$sample_index->{rock_inhibitor_used_at_thaw_flag} = $$sample{rock_inhibitor_used_at_thaw_flag};}


  #TODO Charachterisation data

  push($IMSfiltered->{'objects'}, $sample_index);
}

#$writer->endTag( );
#$writer->end( );
#close($xmlfile);

open(my $json_file, '>', $json_filename_in);
my $json_filtered_out = encode_json($IMSfiltered);
print $json_file $json_filtered_out; #Filtered JSON
close $json_file;


