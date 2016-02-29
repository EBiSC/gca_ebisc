use strict;
use warnings;

package ReseqTrack::EBiSC::IMS;
use namespace::autoclean;
use Moose;
use LWP::UserAgent;
use JSON qw(decode_json);
use HTTP::Request::Common qw(POST);

has 'base_url' => (is => 'rw', isa => 'Str', default => 'cells.ebisc.org');
has 'ua' => (is => 'ro', isa => 'LWP::UserAgent', default => sub {return LWP::UserAgent->new;});

has 'user' => (is => 'rw', isa => 'Str');
has 'pass' => (is => 'rw', isa => 'Str');

sub BUILD {
  my ($self) = @_;
  $self->ua->default_header(Authorization => sprintf('ApiKey %s:%s', $self->user, $self->pass));
  $self->ua->timeout(5);
}

sub find_lines {
  my ($self, %options) = @_;
  my $lines = [];
  my $url_path = 'api/v0/cell-lines/?format=json';
  while ($url_path) {
    my $json = $self->query_api($url_path);
    push(@$lines, @{$json->{objects}});
    $url_path = $json->{meta}{next};
  }
  if ($options{lims_fields}) {
    $lines = $self->subset_lims_fields($lines);
  }
  return {objects=>$lines};
}

sub query_api {
  my ($self, $url_path) = @_;
  my $response = $self->ua->get(sprintf('https://%s/%s', $self->base_url, $url_path));
  die $response->status_line if $response->is_error;
  return decode_json($response->content);
}

sub subset_lims_fields {
  my ($self, $lines) = @_;

  my @filtered;
  foreach my $sample (@$lines) {
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

    push(@filtered, $sample_index);
  }
  return \@filtered;
}



1;
