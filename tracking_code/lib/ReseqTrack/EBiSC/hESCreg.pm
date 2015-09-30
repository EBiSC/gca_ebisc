use strict;
use warnings;

package ReseqTrack::EBiSC::hESCreg;
use namespace::autoclean;
use Moose;
use LWP::UserAgent;
use HTTP::Request;
use JSON qw(decode_json encode_json);

has 'base_url' => (is => 'rw', isa => 'Str', default => 'hpscreg.eu:80');
has 'ua' => (is => 'ro', isa => 'LWP::UserAgent', default => sub {return LWP::UserAgent->new;});

has 'realm' => (is => 'rw', isa => 'Str', default => 'hPSCreg API');
has 'user' => (is => 'rw', isa => 'Str');
has 'pass' => (is => 'rw', isa => 'Str');

sub BUILD {
  my ($self) = @_;
  $self->ua->credentials($self->base_url, $self->realm, $self->user, $self->pass);
  $self->ua->timeout(5);
}

sub find_lines {
  my ($self, %options) = @_;
  my $url = sprintf('http://%s%s', $self->base_url, $options{url}||"/api/full_list");
  my $response = $self->ua->get($url);
  die $response->status_line if $response->is_error;
  my $content = eval{decode_json($response->content);};
  if ($@) {
    die "problem with content from $url\n".$response->content;
  }
  return $content;
}

sub get_line {
  my ($self, $line_name) = @_;
  my $url = sprintf('http://%s/api/export/%s', $self->base_url, $line_name);
  my $response = $self->ua->get($url);
  die $response->status_line if $response->is_error;
  my $content = eval{decode_json($response->content);};
  if ($@) {
    die "problem with content from $url\n".$response->content;
  }
  return $content;
}

sub post_line {
  my ($self, $hash) = @_;
  my $url = sprintf('http://%s/api/create_cell_line', $self->base_url);
  my $req = HTTP::Request->new(POST => $url);
  $req->content_type('application/json');
  $req->content(encode_json($hash));
  #print $req->as_string();

  my $response = $self->ua->request($req);
  #print $response->as_string();
  die $response->status_line if $response->is_error;
  return $response->status_line;
}

my $blank_post_json = '
{
  "form_finished_flag": "",
  "final_name_generated_flag": "",
  "final_submit_flag": "",
  "id": "",
  "validation_status": "",
  "name": "",
  "alternate_name": [
  ],
  "type": "",
  "donor_number": "",
  "donor_cellline_number": "",
  "donor_cellline_subclone_number": "",
  "internal_donor_id": "",
  "internal_donor_ids": [
  ],
  "available_flag": "",
  "same_donor_cell_line_flag": "",
  "same_donor_derived_from_flag": "",
  "registration_reference": "",
  "registration_reference_publication_pubmed_id": "",
  "provider_generator": "",
  "provider_generator_institution_contact": "",
  "provider_owner": "",
  "provider_distributor": [
  ],
  "genetic_information_associated_flag": "",
  "vector_type": "",
  "integrating_vector": "",
  "integrating_vector_other": "",
  "integrating_vector_virus_type": "",
  "integrating_vector_gene_list": [
  ],
  "dev_stage_primary_cell": "",
  "donor_age": "",
  "gender_primary_cell": "",
  "disease_flag": "",
  "excisable_vector_flag": "",
  "primary_celltype_ont_id": "",
  "primary_celltype_name": "",
  "selection_of_clones": "",
  "derivation_gmp_ips_flag": "",
  "available_clinical_grade_ips_flag": "",
  "derivation_xeno_graft_free_flag": "",
  "vector_map_file": "",
  "vector_map_file_enc": "",
  "vector_free_types": [
  ],
  "surface_coating": "",
  "surface_coating_other": "",
  "feeder_cells_flag": "",
  "passage_method": "",
  "passage_method_other": "",
  "passage_method_enzymatic": "",
  "passage_method_enzymatic_other": "",
  "passage_method_enzyme_free": "",
  "passage_method_enzyme_free_other": "",
  "o2_concentration": "",
  "co2_concentration": "",
  "culture_conditions_medium_culture_medium": "",
  "culture_conditions_medium_culture_medium_protocol_file": "",
  "culture_conditions_medium_culture_medium_protocol_file_enc": "",
  "culture_conditions_medium_culture_medium_protocol_2_file": "",
  "culture_conditions_medium_culture_medium_protocol_2_file_enc": "",
  "culture_conditions_medium_culture_medium_protocol_3_file": "",
  "culture_conditions_medium_culture_medium_protocol_3_file_enc": "",
  "certificate_of_analysis_flag": "",
  "undiff_immstain_marker": [
  ],
  "undiff_immstain_marker_passage_number": "",
  "undiff_rtpcr_marker_passage_number": "",
  "undiff_facs_marker_passage_number": "",
  "undiff_morphology_markers_enc_filename": "",
  "undiff_morphology_markers_filename": "",
  "undiff_morphology_markers_description": "",
  "undiff_exprof_markers_method_id": "",
  "undiff_exprof_markers_method_name": "",
  "undiff_exprof_markers_weblink": "",
  "undiff_exprof_markers_enc_filename": "",
  "undiff_exprof_markers_filename": "",
  "virology_screening_flag": "",
  "virology_screening_hiv_1_flag": "",
  "virology_screening_hiv_1_result": "",
  "virology_screening_hbv_flag": "",
  "virology_screening_hbv_result": "",
  "virology_screening_hcv_flag": "",
  "virology_screening_hcv_result": "",
  "virology_screening_mycoplasma_flag": "",
  "virology_screening_mycoplasma_result": "",
  "spontaneous_differentiation_flag": "",
  "directed_differentiation_flag": "",
  "directed_passage_number": "",
  "directed_endo_name": "",
  "directed_endo_ont_id": "",
  "directed_endo_method_file": "",
  "directed_endo_method_file_enc": "",
  "directed_endo_marker_morphology_markers_enc_filename": "",
  "directed_endo_marker_morphology_markers_filename": "",
  "directed_endo_marker_morphology_markers_description": "",
  "directed_endo_marker_exprof_markers_method_id": "",
  "directed_endo_marker_exprof_markers_method_name": "",
  "directed_endo_marker_exprof_markers_weblink": "",
  "directed_endo_marker_exprof_markers_enc_filename": "",
  "directed_endo_marker_exprof_markers_filename": "",
  "directed_meso_name": "",
  "directed_meso_ont_id": "",
  "directed_meso_method_file": "",
  "directed_meso_method_file_enc": "",
  "directed_meso_marker_morphology_markers_enc_filename": "",
  "directed_meso_marker_morphology_markers_filename": "",
  "directed_meso_marker_morphology_markers_description": "",
  "directed_meso_marker_exprof_markers_method_id": "",
  "directed_meso_marker_exprof_markers_method_name": "",
  "directed_meso_marker_exprof_markers_weblink": "",
  "directed_meso_marker_exprof_markers_enc_filename": "",
  "directed_meso_marker_exprof_markers_filename": "",
  "directed_ekto_name": "",
  "directed_ekto_ont_id": "",
  "directed_ekto_flag": "",
  "directed_ekto_method_file": "",
  "directed_ekto_method_file_enc": "",
  "directed_ekto_marker_morphology_markers_enc_filename": "",
  "directed_ekto_marker_morphology_markers_filename": "",
  "directed_ekto_marker_morphology_markers_description": "",
  "directed_ekto_marker_exprof_markers_method_id": "",
  "directed_ekto_marker_exprof_markers_method_name": "",
  "directed_ekto_marker_exprof_markers_weblink": "",
  "directed_ekto_marker_exprof_markers_enc_filename": "",
  "directed_ekto_marker_exprof_markers_filename": "",
  "embryoid_body_differentiation_flag": "",
  "teratoma_formation_differentiation_flag": "",
  "teratoma_formation_passage_number": "",
  "teratoma_formation_endo_flag": "",
  "teratoma_formation_endo_marker_morphology_markers_enc_filename": "",
  "teratoma_formation_endo_marker_morphology_markers_filename": "",
  "teratoma_formation_endo_marker_morphology_markers_description": "",
  "teratoma_formation_endo_marker_exprof_markers_method_id": "",
  "teratoma_formation_endo_marker_exprof_markers_method_name": "",
  "teratoma_formation_endo_marker_exprof_markers_weblink": "",
  "teratoma_formation_endo_marker_exprof_markers_enc_filename": "",
  "teratoma_formation_endo_marker_exprof_markers_filename": "",
  "teratoma_formation_meso_flag": "",
  "teratoma_formation_meso_marker_morphology_markers_enc_filename": "",
  "teratoma_formation_meso_marker_morphology_markers_filename": "",
  "teratoma_formation_meso_marker_morphology_markers_description": "",
  "teratoma_formation_meso_marker_exprof_markers_method_name": "",
  "teratoma_formation_meso_marker_exprof_markers_weblink": "",
  "teratoma_formation_meso_marker_exprof_markers_enc_filename": "",
  "teratoma_formation_meso_marker_exprof_markers_filename": "",
  "teratoma_formation_ekto_flag": "",
  "teratoma_formation_ekto_marker_morphology_markers_enc_filename": "",
  "teratoma_formation_ekto_marker_morphology_markers_filename": "",
  "teratoma_formation_ekto_marker_morphology_markers_description": "",
  "teratoma_formation_ekto_marker_exprof_markers_method_id": "",
  "teratoma_formation_ekto_marker_exprof_markers_method_name": "",
  "teratoma_formation_ekto_marker_exprof_markers_weblink": "",
  "teratoma_formation_ekto_marker_exprof_markers_enc_filename": "",
  "teratoma_formation_ekto_marker_exprof_markers_filename": "",
  "karyotyping_flag": "",
  "hla_flag": "",
  "fingerprinting_flag": "",
  "genetic_modification_flag": "",
  "comment": "",
  "migration_status": "",
  "migration_comments": "",
  "migration_datetime": "",
  "derivation_country": "",
  "data_accurate_and_complete_flag": "",
  "source_platform": "",
  "donor_country_origin": "",
  "ethnicity": "",
  "family_history": "",
  "comparator_cell_line_id": "",
  "comparator_cell_line_type": "",
  "medical_history": "",
  "clinical_information": "",
  "location_primary_tissue_procurement": "",
  "collection_date": "",
  "passage_number_reprogrammed": "",
  "other_culture_environment": "",
  "passage_number_banked": "",
  "number_of_vials_banked": "",
  "genome_wide_genotyping_flag": "",
  "genome_wide_genotyping_ega": "",
  "genome_wide_genotyping_ega_other": "",
  "genome_wide_genotyping_ega_url": "",
  "genome_wide_genotyping_vcf_file": "",
  "genome_wide_genotyping_vcf_file_enc": "",
  "hips_informed_consent_flag": "",
  "hips_consent_form_file": "",
  "hips_consent_form_file_enc": "",
  "hips_provide_copy_of_donor_consent_information_english_file": "",
  "hips_provide_copy_of_donor_consent_information_english_file_enc": "",
  "hips_provide_copy_of_donor_consent_english_file": "",
  "hips_provide_copy_of_donor_consent_english_file_enc": "",
  "hips_future_research_permitted_areas": "",
  "hips_further_constraints_on_use": "",
  "hips_genetic_information_access_policy": "",
  "hips_medical_records_access_consented_organisation_name": "",
  "hips_approval_flag": "",
  "hips_approval_auth_name": "",
  "hips_approval_number": "",
  "hips_third_party_obligations": "",
  "teratoma_formation_method_file": "",
  "teratoma_formation_method_file_enc": ""
}
';

sub blank_post_hash {
  return decode_json($blank_post_json);
}



1;
