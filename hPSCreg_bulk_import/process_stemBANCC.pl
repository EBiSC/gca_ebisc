#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use XML::Simple;
use JSON;
use Try::Tiny;
use Text::Unidecode;
use autodie;
use Data::Dumper;


my ($xmlinfile, $jsonoutfile, $ethicsinfile, $agesexinfile);

GetOptions("xmlinfile=s" => \$xmlinfile,
  "jsonoutfile=s" => \$jsonoutfile,
  "ethicsinfile=s" => \$ethicsinfile,
  "agesexinfile=s" => \$agesexinfile
);

die "missing json xmlinfile" if !$xmlinfile;
die "missing json jsonoutfile" if !$jsonoutfile;
die "missing ethicsinfile" if !$ethicsinfile;
die "missing agesexinfile" if !$agesexinfile;

my %ethics_codes;
open my $fhi, '<', $ethicsinfile or die "could not open $ethicsinfile $!";
my @lines = <$fhi>;
foreach my $line (@lines){
  chomp($line);
  my @parts = split("\t", $line);
  $ethics_codes{$parts[0]} = $parts[1];
}

my (%sex_codes, %age_codes);
open my $fhas, '<', $agesexinfile or die "could not open $agesexinfile $!";
my @agesexlines = <$fhas>;
foreach my $line (@agesexlines){
  chomp($line);
  my @parts = split("\t", $line);
  if ($parts[1]){
    $sex_codes{$parts[0]} = $parts[1];
  }
  if ($parts[2]){
    $age_codes{$parts[0]} = $parts[2];
  }
}

#Override missing diseases
my %disease_overide = (
  "SFC810-03-01" => "Alzheimers",
  "SFC810-03-02" => "Alzheimers",
  "SFC810-03-03" => "Alzheimers",
  "SFC800-03-03" => "Diabetes",
  "SFC800-03-01" => "Diabetes",
  "SFC026-04-10" => "Migraine",
  "SFC888-07-01" => "Diabetes",
  "SFC888-07-02" => "Diabetes",
  "SFC888-07-03" => "Diabetes",
  "BPC321-01-06" => "Dili",
  "BPC321-01-07" => "Dili",
  "BPC321-01-09" => "Dili",
  "BPC339-03-01" => "Dili",
  "BPC340-03-06" => "Longqt"
);

my %age_range;
my $age = 0;
my $age_lower = 0;
while ($age < 100){
  my $age_upper = $age_lower+4;
  $age_range{$age} = "$age_lower\-$age_upper";
  $age++;
  if ($age > ($age_lower+4)){
    $age_lower = $age;
  }
}
while ($age < 140){
  $age_range{$age} = "100-";
  $age++;
}

my $xml_data;
my $xml = new XML::Simple;
$xml_data = $xml->XMLin($xmlinfile,forcearray => 1);

my %lines_already_in_hPSCreg = ('SFC832-03-19' => 1, 'SFC833-03-01' => 1, 'SFC140-04-01' => 1, 'SFC855-03-06' => 1);

my %ethics = (
  "1: STEMBANNC RECRUITED COHORT - UK Diabetes" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "controlled_access",
    hips_provide_copy_of_donor_consent_information_english_file => "StemBANCC PIS Diabetes v2-7.pdf",
    hips_obtain_copy_of_unsigned_consent_form_file => "Stembancc Consent Form v2.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "NRES Committee South Central - Hampshire A",
    hips_approval_number_relation_consent => "13/SC/0179",
    hips_approval_auth_name_proposed_use => "NRES Committee South Central - Hampshire A",
    hips_approval_number_proposed_use => "13/SC/0179",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "1",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "DNA sequencing can only be performed for research into donors specified condition. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "2: UOXF -Bennett - Neuropathy" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "controlled_access",
    hips_provide_copy_of_donor_consent_information_english_file => "Bennet Neuropathy Painful Channelopathies Study PIS Version 2. 07.07.2011.doc",
    hips_obtain_copy_of_unsigned_consent_form_file => "Bennet Neuropathy Painful Channelopathies Study ICF Version 2. 07.07.2011.doc",
    hips_material_pseudonymised_or_anonymised => "anonymised",
    hips_approval_auth_name_relation_consent => "NHS-NRES Committee",
    hips_approval_number_relation_consent => "12/LO/0017",
    hips_approval_auth_name_proposed_use => "NHS-NRES Committee",
    hips_approval_number_proposed_use => "12/LO/0017",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "0",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "Only to be used into research into Painful Channelopathies / Pain syndromes. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "3: UCL - Hardy - Cellular Functions" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "no_information",
    hips_provide_copy_of_donor_consent_information_english_file => "Hardy PD PIS Version 1.1 181207.doc",
    hips_obtain_copy_of_unsigned_consent_form_file => "Hardy PD ICF Version 1.0 300707.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "Royal Free Hospital and Medical School Research Ethics Committee",
    hips_approval_number_relation_consent => "07/H0720/161",
    hips_approval_auth_name_proposed_use => "Royal Free Hospital and Medical School Research Ethics Committee",
    hips_approval_number_proposed_use => "07/H0720/161",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "0",
    hips_consent_expressly_prevents_financial_gain_flag => "0",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "Reseach use restriction , only to be used in Parkinson's Disease. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "4: UOXF - Hu - PD" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "no_information",
    hips_provide_copy_of_donor_consent_information_english_file => "Hu PD Version 5 27-12-11.doc",
    hips_obtain_copy_of_unsigned_consent_form_file => "Hu PD Version 2 27-12-11.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "Berkshire Research Ethics Committee",
    hips_approval_number_relation_consent => "10/H0505/71",
    hips_approval_auth_name_proposed_use => "Berkshire Research Ethics Committee",
    hips_approval_number_proposed_use => "10/H0505/71",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "0",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "Research use restriction, only to be used for research into Parkinson's Disease and other neurodegenerative disorders. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "5: UCL - Hardy - AD" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "no_information",
    hips_provide_copy_of_donor_consent_information_english_file => "John Hardy AD PIS Version 1 23 July 2009.doc",
    hips_obtain_copy_of_unsigned_consent_form_file => "John Hardy AD ICF Version 1 23 July 2009.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "National Hospital and Institute of Neurology Joint REC",
    hips_approval_number_relation_consent => "09/H0716/64",
    hips_approval_auth_name_proposed_use => "National Hospital and Institute of Neurology Joint REC",
    hips_approval_number_proposed_use => "09/H0716/64",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "0",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "Research use restriction, only to be used for research into Dementias. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "7: EUROWABB - Barrett - Diabetes" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "controlled_access",
    hips_provide_copy_of_donor_consent_information_english_file => "Euro-WABB PIS Adult Patient. Version 4.1 25-05-2011.pdf",
    hips_obtain_copy_of_unsigned_consent_form_file => "Euro-WABB Consent Form Adult Patient. Version 4.2 30-06-2011.pdf",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "National Hospital and Institute of Neurology Joint REC",
    hips_approval_number_relation_consent => "11/WM/0127",
    hips_approval_auth_name_proposed_use => "National Hospital and Institute of Neurology Joint REC",
    hips_approval_number_proposed_use => "11/WM/0127",
    hips_documentation_provided_to_donor_flag => "1",
    hips_documentation_provided_to_donor_input => "EURO-WABB.zip",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "0",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "DNA sequencing can only be performed for research into Diabetes. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "8: UOXF - Talbot - Neuropathy" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "no_information",
    hips_provide_copy_of_donor_consent_information_english_file => "Talbot Neuropathy PIS Version 1 1st June 2012.doc",
    hips_obtain_copy_of_unsigned_consent_form_file => "Talbot Neuropathy ICF Version 1 01-06-2012.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "South East Wales Research Ethics Committee",
    hips_approval_number_relation_consent => "12/WA/0186",
    hips_approval_auth_name_proposed_use => "South East Wales Research Ethics Committee",
    hips_approval_number_proposed_use => "12/WA/0186",
    hips_documentation_provided_to_donor_flag => "1",
    hips_documentation_provided_to_donor_input => "Talbot Neuropathy.zip",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "0",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "Research use restriction, only to be used for research into Motor Neuron Diseases. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "9: STEMBANNC RECRUITED COHORT - UK Neuropathy" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "controlled_access",
    hips_provide_copy_of_donor_consent_information_english_file => "StemBANCC PIS Neuropathy v2-6.pdf",
    hips_obtain_copy_of_unsigned_consent_form_file => "Stembancc Consent Form v2.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "NRES Committee South Central - Hampshire A",
    hips_approval_number_relation_consent => "13/SC/0179",
    hips_approval_auth_name_proposed_use => "NRES Committee South Central - Hampshire A",
    hips_approval_number_proposed_use => "13/SC/0179",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "1",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "DNA sequencing can only be performed for research into donors specified condition. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "10: STEMBANNC RECRUITED COHORT - Migraine" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "controlled_access",
    hips_provide_copy_of_donor_consent_information_english_file => "StemBANCC PIS Migraine v2-6.pdf",
    hips_obtain_copy_of_unsigned_consent_form_file => "Stembancc Consent Form v2.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "NRES Committee South Central - Hampshire A",
    hips_approval_number_relation_consent => "13/SC/0179",
    hips_approval_auth_name_proposed_use => "NRES Committee South Central - Hampshire A",
    hips_approval_number_proposed_use => "13/SC/0179",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "1",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "DNA sequencing can only be performed for research into donors specified condition. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "11: STEMBANNC RECRUITED COHORT - Alzheimer's" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "controlled_access",
    hips_provide_copy_of_donor_consent_information_english_file => "StemBANCC PIS Alzheimer's v2-6.pdf",
    hips_obtain_copy_of_unsigned_consent_form_file => "Stembancc Consent Form v2.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "NRES Committee South Central - Hampshire A",
    hips_approval_number_relation_consent => "13/SC/0179",
    hips_approval_auth_name_proposed_use => "NRES Committee South Central - Hampshire A",
    hips_approval_number_proposed_use => "13/SC/0179",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "1",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "DNA sequencing can only be performed for research into donors specified condition. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "12: STEMBANNC RECRUITED COHORT - Bipolar" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "controlled_access",
    hips_provide_copy_of_donor_consent_information_english_file => "StemBANCC PIS Bipolar v2-8.pdf",
    hips_obtain_copy_of_unsigned_consent_form_file => "Stembancc Consent Form v2.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "NRES Committee South Central - Hampshire A",
    hips_approval_number_relation_consent => "13/SC/0179",
    hips_approval_auth_name_proposed_use => "NRES Committee South Central - Hampshire A",
    hips_approval_number_proposed_use => "13/SC/0179",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "1",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "DNA sequencing can only be performed for research into donors specified condition. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "13: STEMBANNC RECRUITED COHORT - Control " => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "controlled_access",
    hips_provide_copy_of_donor_consent_information_english_file => "StemBANCC PIS Healthy controls v2-5.pdf",
    hips_obtain_copy_of_unsigned_consent_form_file => "Stembancc Consent Form v2.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "NRES Committee South Central - Hampshire A",
    hips_approval_number_relation_consent => "13/SC/0179",
    hips_approval_auth_name_proposed_use => "NRES Committee South Central - Hampshire A",
    hips_approval_number_proposed_use => "13/SC/0179",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "1",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "DNA sequencing can only be used as a control for research into other diseases. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "14: STEMBANCC RECRUITED COHORT- Parkinson's Disease " => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "controlled_access",
    hips_provide_copy_of_donor_consent_information_english_file => "StemBANCC PIS Parkinson's v2-6.pdf",
    hips_obtain_copy_of_unsigned_consent_form_file => "Stembancc Consent Form v2.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "NRES Committee South Central - Hampshire A",
    hips_approval_number_relation_consent => "13/SC/0179",
    hips_approval_auth_name_proposed_use => "NRES Committee South Central - Hampshire A",
    hips_approval_number_proposed_use => "13/SC/0179",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "1",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "DNA sequencing can only be performed for research into donors specified condition. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "15: STEMBANCC RECRUITED COHORT- Adverse Drug Responders" => {
    hips_holding_original_donor_consent_contact_info => "zameel.cader\@ndcn.ox.ac.uk",
    hips_consent_pertains_specific_research_project_flag => "0",
    hips_genetic_information_access_policy => "controlled_access",
    hips_provide_copy_of_donor_consent_information_english_file => "StemBANCC PIS Adverse Drug Responders v1-2.pdf",
    hips_obtain_copy_of_unsigned_consent_form_file => "Stembancc Consent Form v2.doc",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "NRES Committee South Central - Hampshire A",
    hips_approval_number_relation_consent => "13/SC/0179",
    hips_approval_auth_name_proposed_use => "NRES Committee South Central - Hampshire A",
    hips_approval_number_proposed_use => "13/SC/0179",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "1",
    hips_third_party_obligations_flag => "1",
    hips_further_constraints_on_use_flag => "0",
    hips_third_party_obligations => "DNA sequencing can only be performed for research into donors specified condition. Material shall not be sold, transplanted into any human being or used to create egg or sperm cells (gametes) or embryos. The material shall not be used for direct exploitation. For the purposes of this, Direct exploitation means to develop for commericalization or to commercialize the Material."
  },
  "16: MRC Biobank - Neuropathy" => {
  #  hips_holding_original_donor_consent_contact_info => "",
  #  hips_consent_pertains_specific_research_project_flag => "",
  #  hips_genetic_information_access_policy => "",
  #  hips_provide_copy_of_donor_consent_information_english_file => "",
  #  hips_obtain_copy_of_unsigned_consent_form_file => "",
  #  hips_material_pseudonymised_or_anonymised => "",
  #  hips_approval_auth_name_relation_consent => "",
  #  hips_approval_number_relation_consent => "",
  #  hips_approval_auth_name_proposed_use => "",
  #  hips_approval_number_proposed_use => "",
  #  hips_documentation_provided_to_donor_flag => "",
  #  hips_consent_permits_future_research_flag => "",
  #  hips_consent_expressly_prevents_financial_gain_flag => "",
  #  hips_third_party_obligations_flag => "",
  #  hips_further_constraints_on_use_flag => "",
  #  hips_third_party_obligations => ""
  },
  "17: Depondt - Migraine" => {
    hips_holding_original_donor_consent_contact_info => "Chantal.Depondt\@ulb.ac.be",
    hips_consent_pertains_specific_research_project_flag => "1",
    hips_genetic_information_access_policy => "no_information",
    hips_provide_copy_of_donor_consent_information_english_file => "",
    hips_obtain_copy_of_unsigned_consent_form_file => "",
    hips_material_pseudonymised_or_anonymised => "pseudonymised",
    hips_approval_auth_name_relation_consent => "Ethics Committee Erasme Hospital",
    hips_approval_number_relation_consent => "13/SC/0179",
    hips_approval_auth_name_proposed_use => "Ethics Committee Erasme Hospital",
    hips_approval_number_proposed_use => "13/SC/0179",
    hips_documentation_provided_to_donor_flag => "0",
    hips_consent_permits_future_research_flag => "1",
    hips_consent_expressly_prevents_financial_gain_flag => "0",
    hips_third_party_obligations_flag => "0",
    hips_further_constraints_on_use_flag => "1",
    hips_further_constraints_on_use => "Restricted to research into epilepsy."
  }
);

my %diseases = (
  Alzheimers => {
    disease_flag => "true", 
    primary => "true", 
    purl => "http:\/\/www.ebi.ac.uk\/efo\/EFO_0000249", 
    purl_name => "Alzheimers disease", 
    synonyms => ["Disease", "Alzheimer", "Dementia in Alzheimer's disease", "unspecified (disorder)", "Presenile Alzheimer Dementia", "ALZHEIMERS DIS", "Alzheimers", "sporadic Alzheimer's disease", "DAT - Dementia Alzheimer's type", "Dementia in Alzheimer's disease", "Alzheimer's disease", "NOS", "Alzheimer Dementia", "Presenile", "Dementia", "Alzheimer Type", "Alzheimer Dementia", "Alzheimer's Dementia", "Alzheimer's", "Dementia", "Presenile", "[X]Dementia in Alzheimer's disease (disorder)", "ALZHEIMER DIS", "AD", "[X]Dementia in Alzheimer's disease", "AD - Alzheimer's disease", "Disease", "Alzheimer's", "Alzheimer Disease", "Dementia", "Presenile Alzheimer", "Alzheimer Type Dementia", "Dementia in Alzheimer's disease (disorder)", "Alzheimer's disease (disorder)", "Alzheimers Dementia", "Dementia of the Alzheimer's type"]
  },
  Neuropathy => {
    disease_flag => "true", 
    primary => "true", purl => "http:\/\/www.ebi.ac.uk\/efo\/EFO_0004149", 
    purl_name => "neuropathy"
  },
  Parkinsons => {
    disease_flag => "true", 
    primary => "true", 
    purl => "http:\/\/www.ebi.ac.uk\/efo\/EFO_0002508", 
    purl_name => "Parkinson's disease", 
    synonyms => ["Parkinson's syndrome", "Parkinsons", "Primary Parkinsonism", "Parkinsons disease", "Parkinson disease", "Parkinson's disease (disorder)", "Parkinson's disease NOS", "Parkinson Disease", "Idiopathic", "PARKINSON DIS", "Paralysis agitans", "IDIOPATHIC PARKINSONS DIS", "PARKINSON DIS IDIOPATHIC", "Parkinsonism", "Primary", "Parkinson's Disease", "Lewy Body", "IDIOPATHIC PARKINSON DIS", "Idiopathic PD", "Idiopathic Parkinson Disease", "Lewy Body Parkinson's Disease", "Parkinsonian disorder", "LEWY BODY PARKINSON DIS", "Parkinson's", "Idiopathic Parkinson's Disease", "Parkinson's disease NOS (disorder)", "Lewy Body Parkinson Disease", "PARKINSONS DIS IDIOPATHIC", "PARKINSONS DIS", "Parkinson's Disease", "Idiopathic", "Parkinson syndrome", "PARKINSONS DIS LEWY BODY"]
  },
  Migraine  => {
    disease_flag => "true", 
    primary => "true", 
    purl => "http:\/\/www.ebi.ac.uk\/efo\/EFO_0003821", 
    purl_name => "migraine disorder", 
    synonyms => ["Migraine", "Acute Confusional", "Migraine", "Hemicrania", "Sick Headache", "Migraine", "Abdominal", "Migraines", "Migraines", "Acute Confusional", "Hemicrania Migraine", "Migraine Variant", "Acute Confusional Migraines", "Migraine Syndrome", "Cervical", "Abdominal Migraine", "Headaches", "Sick", "Disorders", "Migraine", "Disorder", "Migraine", "Variants", "Migraine", "Migraine Headache", "Acute Confusional Migraine", "Migraines", "Abdominal", "Headache", "Sick", "Cervical Migraine Syndrome", "Migraine", "Sick Headaches", "Migraine Headaches", "Hemicrania Migraines", "Migraine Variants", "Variant", "Migraine", "Status Migrainosus", "Migraine Disorders", "Cervical Migraine Syndromes", "Headache", "Migraine", "Headaches", "Migraine", "Migraines", "Hemicrania", "Abdominal Migraines", "Migraine Syndromes", "Cervical"]
  },
  Diabetes => {
    disease_flag => "true", 
    primary => "true", 
    purl => "http:\/\/www.ebi.ac.uk\/efo\/EFO_0000400", 
    purl_name => "diabetes mellitus", 
    synonyms => ["Diabetes mellitus (disorder)", "Diabetes", "Diabetes mellitus", "NOS", "DM - Diabetes mellitus", "Diabetes NOS"]
  },
  Bipolar => {
    disease_flag => "true", 
    primary => "true", 
    purl => "http:\/\/www.ebi.ac.uk\/efo\/EFO_0000289", 
    purl_name => "bipolar disorder", 
    synonyms => ["Psychoses", "Manic-Depressive", "Bipolar affective disorder", "current episode depression (disorder)", "Manic bipolar I disorder", "Manic-depressive psychosis", "mixed bipolar affective disorder", "NOS (disorder)", "Disorder", "Bipolar", "Manic bipolar I disorder (disorder)", "Manias", "Bipolar Disorders", "Affective Bipolar Psychosis", "Psychosis", "Bipolar Affective", "Psychosis", "Manic-Depressive", "Manic Depressive Psychosis", "MANIC DIS", "Bipolar Depression", "BIPOLAR DIS", "Manic Disorders", "Unspecified bipolar affective disorder", "NOS (disorder)", "Bipolar affective disorder", "Manic States", "Manic Depressive disorder", "Unspecified bipolar affective disorder", "State", "Manic", "Psychoses", "Manic Depressive", "MANIC DEPRESSIVE ILLNESS", "Mania", "bipolar disorder manic phase", "Unspecified bipolar affective disorder", "NOS", "Psychoses", "Bipolar Affective", "Unspecified bipolar affective disorder", "unspecified (disorder)", "Unspecified bipolar affective disorder", "unspecified", "Psychosis", "Manic Depressive", "Bipolar affective disorder ", "current episode mixed (disorder)", "Disorder", "Manic", "Manic-Depressive Psychoses", "Manic Disorder", "States", "Manic", "mixed bipolar disorder", "[X]Bipolar affective disorder", "unspecified (disorder)", "Unspecified bipolar affective disorder (disorder)", "Bipolar disorder", "unspecified", "Bipolar Affective Psychosis", "Manic-depressive syndrome NOS", "Manic Bipolar Affective disorder", "Manic State", "Bipolar affective disorder", "manic", "unspecified degree", "Bipolar disorder (disorder)", "mixed bipolar affective disorder (disorder)", "Affective Psychosis", "Bipolar", "[X]Bipolar affective disorder", "unspecified", "bipolar disease", "Bipolar affective disorder", "mixed", "unspecified degree", "MDI - Manic-depressive illness", "Manic-depressive illness", "Bipolar disorder", "NOS", "BIPOLAR DISORDER NOS", "mixed bipolar I disorder (disorder)", "Depression", "Bipolar", "Depressive-manic psych.", "Manic-Depression"]
  },
  Longqt => {
    disease_flag => "true", 
    primary => "true", 
    purl => "http:\/\/www.orpha.net\/ORDO\/Orphanet_768", 
    purl_name => "Familial long QT syndrome", 
    synonyms => ["Congenital long QT syndrome"]
  },
  Dili => {
    disease_flag => "true", 
    primary => "true", 
    purl => "http:\/\/www.ebi.ac.uk\/efo\/EFO_0004228", 
    purl_name => "drug-induced liver injury", 
    synonyms => ["Liver Injury", "Drug-Induced", "Drug-Induced Liver Disease", "Toxic Hepatitis", "Hepatitis", "Toxic", "Hepatitis", "Drug-Induced"]
  }
  );

#Get pathogen status of parent lines
my %pathogen_status;
my %donor_names;
my %blood_cells;
CELLLINE:
for (@{ $xml_data->{'CellLine'} }) {
  my $cellLine = $_;
  next CELLLINE if $$cellLine{name}[0] eq "SF155"; #TODO Remove exclusion of these lines when corrected in StemDB is missing cell type
  my $donor_id = $$cellLine{name}[0];
  $donor_id =~ /^\D+(\d*)/;
  $donor_id = $1;
  if ($$cellLine{cell_type}[0] eq "Fibroblast" or $$cellLine{cell_type}[0] eq "Blood"){
    $pathogen_status{$donor_id} = $$cellLine{pathogen}[0];
    $donor_names{$donor_id} = $$cellLine{name}[0];
  }
  if ($$cellLine{cell_type}[0] eq "Blood"){
    $blood_cells{$donor_id} = 1;
  }
}

#Process iPS lines
my %cellLines;
my $i = 1;
CELLLINE:
for (@{ $xml_data->{'CellLine'} }) {
  my $cellLine = $_;
  next CELLLINE if $$cellLine{name}[0] eq "SF155"; #TODO Remove exclusion of these lines when corrected in StemDB is missing cell type
  if (!$lines_already_in_hPSCreg{$$cellLine{name}[0]} and $$cellLine{cell_type}[0] eq "iPS"){
    my $donor_id = $$cellLine{name}[0];
    $donor_id =~ /^\D+(\d*)/;
    $donor_id = $1;   
    my $gender = lc($$cellLine{sex}[0]);
    if ($gender eq "not known"){
      $gender = "unknown";
    }
    my %cellLine_doc = (
      donor => {donor_internal_ids__list_entry_name => [$$cellLine{external_patient_header_id}[0], $donor_names{$donor_id}], gender => $gender},
      source_platform => "ebisc",
      type_name => "hiPSC",
      vector_type => "non_integrating",
      non_integrating_vector => "sendai_virus",
      culture_conditions_medium_culture_medium => "mtesr_1",
      karyotyping_flag => "1",
      karyotyping_karyotype => "No abnormalities detected",
      karyotyping_method => "molecular_snp",
      fingerprinting_flag => "0",
      genetic_modification_flag => "0",
      available_flag => "1",
      availability_restrictions => "with_restrictions",
      primary_celltype_purl => "http:\/\/purl.obolibrary.org\/obo\/CL_0000057",
      primary_celltype_ont_name => "fibroblast",
      primary_celltype_ont_id => "CL_0000057",
      primary_celltype_name => "fibroblast",
      usage_approval_flag => ["research_only"],
      o2_concentration => "21",
      co2_concentration => "5",
      surface_coating => "matrigel",
      passage_method => "enzyme_free",
      passage_method_enzyme_free => "edta",
      feeder_cells_flag => "0",
      virology_screening_mycoplasma_flag =>  "1",
      virology_screening_mycoplasma_result => "negative",

      #Universal ethics responses
      hips_consent_obtained_from_donor_of_tissue_flag => "1",
      hips_no_pressure_stat_flag => "1",
      hips_derived_information_influence_personal_future_treatment_flag => "1",
      hips_provide_copy_of_donor_consent_information_english_flag => "1",
      hips_informed_consent_flag => "0",
      hips_holding_original_donor_consent_flag => "1",
      hips_obtain_copy_of_unsigned_consent_form_flag => "1",
      hips_consent_prevents_ips_derivation_flag => "0",
      hips_consent_prevents_availability_to_worldwide_research_flag => "0",
      hips_ethics_review_panel_opinion_relation_consent_form_flag => "1",
      hips_consent_prevents_derived_cells_availability_to_worldwide_research_flag => "0",
      hips_donor_financial_gain_flag => "0",
      hips_ethics_review_panel_opinion_project_proposed_use_flag => "1",
      hips_consent_by_qualified_professional_flag => "1",
      hips_consent_expressly_prevents_commercial_development_flag => "0",
      hips_consent_permits_stop_of_derived_material_use_flag => "0",
      hips_consent_permits_delivery_of_information_and_data_flag => "0",
      hips_ethics_review_panel_opinion_relation_consent_form_flag => "1",
    );
    print $donor_id, "\n";
    next CELLLINE if $ethics_codes{$donor_id} eq "16: MRC Biobank - Neuropathy"; #TODO Remove exclusion of these lines when given ethics go ahead from RC
    next CELLLINE if $ethics_codes{$donor_id} eq "17: Depondt - Migraine"; #TODO Remove exclusion of these lines when given ethics go ahead from RC
    for my $key (keys(%{$ethics{$ethics_codes{$donor_id}}})){
      $cellLine_doc{$key} = $ethics{$ethics_codes{$donor_id}}{$key};
    }
    my %each_disease;
    if ($$cellLine{disease}){
      $cellLine_doc{disease_flag} = "1";
      $cellLine_doc{donor}{disease_flag} = "true";
      my $mutation = unidecode($$cellLine{mutation}[0]);
      $mutation =~ s/\n/ /g;
      $mutation =~ s/^"(.*)"$/$1/;
      my %variant = (free_text => [$mutation]);
      if ($diseases{$$cellLine{disease}[0]}){
        for my $key (keys($diseases{$$cellLine{disease}[0]})){
          $each_disease{$key} = $diseases{$$cellLine{disease}[0]}{$key};
        }
        push(@{$each_disease{variants}}, \%variant);
        push(@{$cellLine_doc{donor}{diseases}}, \%each_disease);
      }else{
        die "missing disease information for $$cellLine{disease}[0]";
      }
    }elsif (exists $disease_overide{$$cellLine{name}[0]}){
      $cellLine_doc{disease_flag} = "1";
      $cellLine_doc{donor}{disease_flag} = "true";
      if ($diseases{$disease_overide{$$cellLine{name}[0]}}){
        for my $key (keys($diseases{$disease_overide{$$cellLine{name}[0]}})){
          $each_disease{$key} = $diseases{$disease_overide{$$cellLine{name}[0]}}{$key};
        }
        push(@{$cellLine_doc{donor}{diseases}}, \%each_disease);
      }else{
        die "missing disease information for $$cellLine{disease}[0]";
      }
    }
    else{
      $cellLine_doc{disease_flag} = "0";
      $cellLine_doc{donor}{disease_flag} = "false";
    }
    if ($pathogen_status{$donor_id}){
      if ($pathogen_status{$donor_id} eq "Negative"){
        $cellLine_doc{virology_screening_flag} = "1";
        $cellLine_doc{virology_screening_hiv_1_flag} = "1";
        $cellLine_doc{virology_screening_hbv_flag} = "1";
        $cellLine_doc{virology_screening_hcv_flag} = "1";
        $cellLine_doc{virology_screening_hiv_1_result} = "negative";
        $cellLine_doc{virology_screening_hbv_result} = "negative";
        $cellLine_doc{virology_screening_hcv_result} = "negative";
      }
    }
    #Overwrite age and sex from MDA
    if ($sex_codes{$$cellLine{name}[0]}){
      if ($sex_codes{$$cellLine{name}[0]} eq "M"){
        $cellLine_doc{donor}{gender} = "male"
      }elsif ($sex_codes{$$cellLine{name}[0]} eq "F"){
        $cellLine_doc{donor}{gender} = "female"
      }
    }
    if ($age_codes{$$cellLine{name}[0]}){
      $cellLine_doc{donor}{donor_age} = $age_range{$age_codes{$$cellLine{name}[0]}};
    }
    if ($blood_cells{$donor_id}){
      $cellLine_doc{primary_celltype_purl} = "http:\/\/purl.obolibrary.org\/obo\/CL_0000081",
      $cellLine_doc{primary_celltype_ont_name} = "blood cell",
      $cellLine_doc{primary_celltype_ont_id} = "CL_0000081",
      $cellLine_doc{primary_celltype_name} = "blood cell",
    }
    if ($$cellLine{name}[0] =~ m/^BP/){
      $cellLine_doc{primary_celltype_purl} = "http:\/\/purl.obolibrary.org\/obo\/CL_0000765",
      $cellLine_doc{primary_celltype_ont_name} = "erythroblast",
      $cellLine_doc{primary_celltype_ont_id} = "CL_0000765",
      $cellLine_doc{primary_celltype_name} = "PBMC erythroblasts",
    }
    push(@{$cellLine_doc{alternate_name}}, $$cellLine{name}[0]);
    #Add line to set
    push(@{$cellLines{cellLines}}, \%cellLine_doc);
  }
}

my $jsonout = encode_json(\%cellLines);
open my $fho, '>', $jsonoutfile or die "could not open $jsonoutfile $!";
print $fho $jsonout;
close($fho);