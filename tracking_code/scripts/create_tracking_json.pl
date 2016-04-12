#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use ReseqTrack::EBiSC::BioSampleUtils;
use ReseqTrack::EBiSC::hESCreg;
use ReseqTrack::EBiSC::IMS;
use ReseqTrack::EBiSC::LimsUtils;
use JSON qw();

my ($hESCreg_user, $hESCreg_pass, $IMS_user, $IMS_pass);

GetOptions("hESCreg_user=s" => \$hESCreg_user,
    "hESCreg_pass=s" => \$hESCreg_pass,
    "IMS_user=s" => \$IMS_user,
    "IMS_pass=s" => \$IMS_pass,
);
die "missing credentials" if !$hESCreg_user || !$hESCreg_pass || !$IMS_user || !$IMS_pass;

my %discovered;
my %discovered_no_biosample;

while (my ($line_name, $biosample_hash) = each %{ReseqTrack::EBiSC::BioSampleUtils::find_lines()}) {
  if ($biosample_hash->{id}) {
    $discovered{$biosample_hash->{id}} = {biosample => $biosample_hash};
  }
  else {
    $discovered_no_biosample{$line_name} = {biosample => $biosample_hash};
  }
}

my $hESCreg = ReseqTrack::EBiSC::hESCreg->new(
  user => $hESCreg_user,
  pass => $hESCreg_pass,
);
LINE:
foreach my $line_name (@{$hESCreg->find_lines()}) {
  my $line = eval{$hESCreg->get_line($line_name);};
  next LINE if !$line || $@;
  my $biosample_id = $line->{biosamples_id} && $line->{biosamples_id} =~ /^SAM.*/ ? $& : undef;
  if (!$biosample_id) {
    NAME:
    foreach my $possible_name ($line_name, @{$line->{alternate_name}}) {
      my ($biosample) = grep {$_ && $_->property('Sample Name')->values->[0] eq $possible_name} @{BioSD::search_for_samples($possible_name)};
      next NAME if !$biosample;
      $biosample_id = $biosample->id;
      last NAME;
    }
  }
  my $line_output = $biosample_id ? \$discovered{$biosample_id} : \$discovered_no_biosample{$line->{name}};
  ${$line_output}->{hESCreg} = {
    name => $line->{name},
    exported => {error => 0},
    validated => {error => $line->{validation_status} == 1 ? 0 : 1},
    alternate_names => $line->{alternate_name},
    biosample_id => $line->{biosamples_id},
    donor_biosample_id => $line->{biosamples_donor_id},
  };

  if ($biosample_id && !${$line_output}->{biosample} && $discovered_no_biosample{$line->{name}}) {
      ${$line_output}->{biosample} = $discovered_no_biosample{$line->{name}}{biosample};
      delete $discovered_no_biosample{$line->{name}};
  }

  if ($biosample_id && !${$line_output}->{biosample}) {
    ALT:
    foreach my $name ($line->{name}, @{$line->{alternate_name}}) {
      if ($discovered_no_biosample{$name}) {
          ${$line_output}->{biosample} = $discovered_no_biosample{$name}{biosample};
          delete $discovered_no_biosample{$name};
          last ALT;
      }
    }
  }

}

my $IMS = ReseqTrack::EBiSC::IMS->new(
  user => $IMS_user,
  pass => $IMS_pass,
);

foreach my $line (@{$IMS->find_lines->{objects}}) {
  my $biosample_id = $line->{biosamples_id} && $line->{biosamples_id} =~ /^SAM.*/ ? $& : undef;
  if (!$biosample_id) {
    NAME:
    foreach my $possible_name ($line->{name}, @{$line->{alternate_names}}) {
      my ($biosample) = grep {$_ && $_->property('Sample Name')->values->[0] eq $possible_name} @{BioSD::search_for_samples($possible_name)};
      next NAME if !$biosample;
      $biosample_id = $biosample->id;
      last NAME;
    }
  }
  my $line_output = $biosample_id ? \$discovered{$biosample_id} : \$discovered_no_biosample{$line->{name}};
  ${$line_output}->{IMS} = {
    name => $line->{name},
    exported => {error => 0},
    alternate_names => $line->{alternate_names},
    biosample_id => $line->{biosamples_id},
    donor_biosample_id => $line->{donor}{biosamples_id},
    flag_go_live => $line->{flag_go_live},
    availability => $line->{availability},
    cellline_certificate_of_analysis  => $line->{cellline_certificate_of_analysis}{certificate_of_analysis_flag},
    cell_line_information_packs => $line->{cell_line_information_packs},
    batches => $line->{batches}
  };

  if ($biosample_id && !${$line_output}->{biosample} && $discovered_no_biosample{$line->{name}}) {
      ${$line_output}->{biosample} = $discovered_no_biosample{$line->{name}}{biosample};
      ${$line_output}->{hESCreg} = $discovered_no_biosample{$line->{name}}{hESCreg};
      delete $discovered_no_biosample{$line->{name}};
  }
}

#TODO Rework to look at XML from LIMS
foreach my $batch ( @{ReseqTrack::EBiSC::LimsUtils::find_batches()}) {
  my $line_output = ReseqTrack::EBiSC::LimsUtils::find_correct_line_hash($batch, \%discovered)
                 || ReseqTrack::EBiSC::LimsUtils::find_correct_line_hash($batch, \%discovered_no_biosample);
  if (!$line_output) {
    $discovered_no_biosample{$batch->{cell_line}} //= {};
    $line_output = $discovered_no_biosample{$batch->{cell_line}};
  }

  $line_output->{LIMS} //= {batches => []};
  my %batch_hash = (
    biosample_id => $batch->{biosamples_batch_id},
    id => $batch->{batch_id},
    name => $batch->{cell_line},
    missing => ReseqTrack::EBiSC::LimsUtils::list_missing_data($batch),
  );
  push(@{$line_output->{LIMS}{batches}}, \%batch_hash);

}


LINE:
while (my ($biosample_id, $line_hash) = each %discovered) {
  if (! $line_hash->{IMS}) {
    $line_hash->{IMS} = {
      exported => {error => 1},
    };
  }
  if (! $line_hash->{hESCreg}) {
    $line_hash->{hESCreg} = {
      exported => {error => 1},
      validated => {error =>1},
    };
  }

  if (! $line_hash->{LIMS}) {
    $line_hash->{LIMS} = {
      batches => [],
    };
  }

  if ($line_hash->{biosample}) {
    $line_hash->{biosample}{exported}{error} = BioSD::fetch_sample($biosample_id) ? 0 : 1;
  }
  elsif (my $biosample = BioSD::fetch_sample($biosample_id)) {
      $line_hash->{biosample} = {
        id => $biosample_id,
        exported => {error => 0},
        name => $biosample->property('Sample Name')->values->[0],
        batch_donor_link => {error => 0},
        batch_line_link => {error => 0},
      };
  }
  else {
    $line_hash->{biosample} = {
      exported => {error => 1},
      batch_donor_link => {error => 0},
      batch_line_link => {error => 0},
    };
  }
}


my %output = (lines => []);
while (my ($biosample_id, $line_hash) = each %discovered) {
  my $name = List::Util::first {$_ && $_ =~ /[A-Z]{2,5}i[A-Z0-9]{3}-[A-Z](-[A-Z0-9])?/ } ($line_hash->{hESCreg}{name}, $line_hash->{IMS}{name}, $line_hash->{biosample}{name});
  $line_hash->{consensus}{name} = {val => $name || '', error => $name ? 0 : 1,
        error_string => $name ? '' : 'could not find a name that looked like a hPSCreg name in any of the services (hPSCreg, IMS, BioSamples)',
  };
  $line_hash->{consensus}{biosample_id} = {val => $biosample_id, error => 0, error_string => ''};
  push(@{$output{lines}}, $line_hash);
}


my $no_biosample_count = 0;
LINE:
while (my ($hescreg_name, $line_hash) = each %discovered_no_biosample) {
  $line_hash->{biosample} = {
    exported => {error => 1},
    batch_donor_link => {error => 0},
    batch_line_link => {error => 0},
  };
  if (! $line_hash->{IMS}) {
    $line_hash->{IMS} = {
      exported => {error => 1},
    }
  }
  if (! $line_hash->{hESCreg}) {
    $line_hash->{hESCreg} = {
      exported => {error => 1},
      validated => {error => 1},
    }
  }

  if (! $line_hash->{LIMS}) {
    $line_hash->{LIMS} = {
      batches => [],
    };
  }

  my $name = List::Util::first {$_ && $_ =~ /[A-Z]{2,5}i[A-Z0-9]{3}-[A-Z](-[A-Z0-9])?/ } ($line_hash->{hESCreg}{name}, $line_hash->{IMS}{name}, map {$_->{name}} @{$line_hash->{LIMS}{batches}});
  $line_hash->{consensus}{name} = {val => $name || $hescreg_name, error => $name ? 0 : 1,
        error_string => $name ? '' : 'could not find a name that looked like a hPSCreg name in any of the services (hPSCreg, IMS, BioSamples)',
  };
  $line_hash->{consensus}{biosample_id} = {val => '', error => 1,
        error_string => 'could not find a BioSamples ID in any of the services (hPSCreg, IMS, BioSamples)',
  };
  push(@{$output{lines}}, $line_hash);
}


foreach my $line_hash (@{$output{lines}}) {

  if (my $donor_biosample_id = $line_hash->{biosample}{batch_donor_link}{id} || $line_hash->{hESCreg}{donor_biosample_id} || $line_hash->{IMS}{donor_biosample_id}) {
    if (BioSD::fetch_sample($donor_biosample_id)) {
      $line_hash->{donor_biosample} = {exported =>{error => 0}, id => $donor_biosample_id};
    }
    else {
      $line_hash->{donor_biosample} = {exported =>{error => 1}, id => $donor_biosample_id};
    }
  }
  else {
      $line_hash->{donor_biosample} = {exported =>{error => 1}};
  }

  $line_hash->{IMS}{exported} ||= {error => 1};

  $line_hash->{LIMS}{missing_data} = {error => 0};
  $line_hash->{LIMS}{name_batch_id_consistent} = {error => 0};
  foreach my $batch (@{$line_hash->{LIMS}{batches}}) {
    $line_hash->{LIMS}{missing_data}{error} ||= scalar @{$batch->{missing}} ? 1 : 0;
    if ($batch->{name} ne $line_hash->{consensus}{name}{val} || ! scalar grep {$batch->{biosample_id} eq $_} @{$line_hash->{biosample}{batches}} ) {
      $line_hash->{LIMS}{name_batch_id_consistent}{error} ||= 1;
      $batch->{name_batch_id_consistent} = 0;
    }
    else {
      $batch->{name_batch_id_consistent} = 1;
    }
  }
  $line_hash->{LIMS}{missing_data}{error_string} = $line_hash->{LIMS}{missing_data}{error} ? 'One or more batches in "LIMS" is missing some data' : '';
  $line_hash->{LIMS}{name_batch_id_consistent}{error_string} = $line_hash->{LIMS}{name_batch_id_consistent}{error} ? 'One or more batches in "LIMS" has an inconsistency between name and biosample id' : '';


  my %tests = (
    'IMS exports the cell line' => $line_hash->{IMS}{exported}{error} ? 'fail' : 'pass',
    'hPSCreg exports the cell line' => $line_hash->{hESCreg}{exported}{error} ? 'fail' : 'pass',
    'BioSamples exports the cell line' => $line_hash->{biosample}{exported}{error} ? 'fail' : 'pass',
    'IMS exports a cell line name (where line is exported)' => $line_hash->{IMS}{exported}{error} ? 'cannot test'
                                  : !$line_hash->{IMS}{name} ? 'fail' : 'pass',
    'IMS exports a biosample ID (where line is exported)' => $line_hash->{IMS}{exported}{error} ? 'cannot test'
                                  : !$line_hash->{IMS}{biosample_id} ? 'fail' : 'pass',
    'IMS exports a donor biosample ID (where line is exported)' => $line_hash->{IMS}{exported}{error} ? 'cannot test'
                                  : !$line_hash->{IMS}{donor_biosample_id} ? 'fail' : 'pass',
    'hPSCreg exports a cell line name (where line is exported)' => $line_hash->{hESCreg}{exported}{error} ? 'cannot test'
                                  : !$line_hash->{hESCreg}{name} ? 'fail' : 'pass',
    'hPSCreg exports a biosample ID (where line is exported)' => $line_hash->{hESCreg}{exported}{error} ? 'cannot test'
                                  : !$line_hash->{hESCreg}{biosample_id} ? 'fail' : 'pass',
    'hPSCreg exports a donor biosample ID (where line is exported)' => $line_hash->{hESCreg}{exported}{error} ? 'cannot test'
                                  : !$line_hash->{hESCreg}{donor_biosample_id} ? 'fail' : 'pass',
    'name in IMS consistent with name in hPSCreg (where both have a name)' => $line_hash->{IMS}{exported}{error}  || !$line_hash->{IMS}{name} ? 'cannot test'
                                  : $line_hash->{hESCreg}{exported}{error}  || !$line_hash->{hESCreg}{name} ? 'cannot test'
                                  : $line_hash->{IMS}{name} eq $line_hash->{hESCreg}{name} ? 'pass' : 'fail',
    'biosample id in IMS consistent with BioSamples database (where both have a biosample id)' => $line_hash->{IMS}{exported}{error}  || !$line_hash->{IMS}{biosample_id} ? 'cannot test'
                                  : $line_hash->{biosample}{exported}{error}  || $line_hash->{biosample}{batch_line_link}{error} || !$line_hash->{biosample}{id} ? 'cannot test'
                                  : $line_hash->{biosample}{id} eq $line_hash->{IMS}{biosample_id} ? 'pass' : 'fail',
    'biosample id in hPSCreg consistent with BioSamples database (where both have an id)' => $line_hash->{hESCreg}{exported}{error}  || !$line_hash->{hESCreg}{biosample_id} ? 'cannot test'
                                  : $line_hash->{biosample}{exported}{error}  || $line_hash->{biosample}{batch_line_link}{error} || !$line_hash->{biosample}{id} ? 'cannot test'
                                  : $line_hash->{biosample}{id} eq $line_hash->{hESCreg}{biosample_id} ? 'pass' : 'fail',
    'biosample id in IMS consistent with biosample id in hPSCreg (where both have an id)' => $line_hash->{IMS}{exported}{error}  || !$line_hash->{IMS}{biosample_id} ? 'cannot test'
                                  : $line_hash->{hESCreg}{exported}{error}  || !$line_hash->{hESCreg}{biosample_id} ? 'cannot test'
                                  : $line_hash->{hESCreg}{biosample_id} eq $line_hash->{IMS}{biosample_id} ? 'pass' : 'fail',
    'donor biosample id in IMS consistent with BioSamples database (where both export an id)' => $line_hash->{IMS}{exported}{error}  || !$line_hash->{IMS}{donor_biosample_id} ? 'cannot test'
                                  : !$line_hash->{donor_biosample}{exported} ? 'cannot test'
                                  : $line_hash->{donor_biosample}{id} eq $line_hash->{IMS}{donor_biosample_id} ? 'pass' : 'fail',
    'donor biosample id in hPSCreg consistent with BioSamples database (where both export an id)' => $line_hash->{hESCreg}{exported}{error}  || !$line_hash->{hESCreg}{donor_biosample_id} ? 'cannot test'
                                  : !$line_hash->{donor_biosample}{exported} ? 'cannot test'
                                  : $line_hash->{donor_biosample}{id} eq $line_hash->{hESCreg}{donor_biosample_id} ? 'pass' : 'fail',
    'Biosamples exports the donor (where donor id is known)' => !$line_hash->{biosample}{batch_donor_link}{id} && !$line_hash->{hESCreg}{donor_biosample_id}  && !$line_hash->{IMS}{donor_biosample_id} ? 'cannot test'
                                  : $line_hash->{donor_biosample}{exported}{error} ? 'fail' : 'pass',
    'Biosamples batches have explicit link to cell line & consistent with derived-from' => $line_hash->{biosample}{batch_line_link}{error}  ? 'fail' : 'pass',
    'Biosamples batches have explicit link to donor' => $line_hash->{biosample}{batch_donor_link}{error}  ? 'fail' : 'pass',
    '"LIMS" data complete for all batches' => !$line_hash->{LIMS}{batches}[0] ? 'cannot test' 
                                  : $line_hash->{LIMS}{missing_data}{error} ? 'fail' : 'pass',
    '"LIMS" batch id and cell line name are consistent with BioSamples' => !$line_hash->{LIMS}{batches}[0] ? 'cannot test' 
                                  : $line_hash->{LIMS}{name_batch_id_consistent}{error} ? 'fail' : 'pass',
    'Line marked go live but no CLIP loaded' => !$line_hash->{IMS}{flag_go_live} ? 'cannot test' : !$line_hash->{IMS}{cell_line_information_packs} ? 'fail' : 'pass',
    'Line marked go live but no batch data found' => !$line_hash->{IMS}{flag_go_live} ? 'cannot test' : !$line_hash->{IMS}{batches}[0] ? 'fail' : 'pass',
    'Line marked go live but is not visible in public IMS' => !$line_hash->{IMS}{flag_go_live} ? 'cannot test' : $line_hash->{IMS}{availability} eq 'Stocked by ECACC' || $line_hash->{IMS}{availability} eq 'Expand to order' ? 'pass' : 'fail', #FIXME THIS IS NOT TESTING WHETHER ITS VISIBLE, CHECK WITH MAJA FOR LOGIC
    #'Line marked go live but no cofa for batches' => !$line_hash->{IMS}{flag_go_live} ? 'cannot test' : !$line_hash->{IMS}{batches}[0] ? 'cannot test' :
    #Stocked by ECACC
  );
  
  
  print "\n", $line_hash->{IMS}{name}, "\n";
  print $line_hash->{IMS}{flag_go_live}, "\n";
  print $line_hash->{IMS}{availability}, "\n";
  print $tests{'Line marked go live but is not visible in public IMS'}, "\n";

  my $ims_name_error = ! $line_hash->{IMS}{name} ? 'IMS does not export any name for this cell line'
                        : $line_hash->{hESCreg}{name} && $line_hash->{IMS}{name} ne $line_hash->{hESCreg}{name} ? 'IMS name does not match the name in hPSCreg'
                        : '';
  my $ims_biosample_error = ! $line_hash->{IMS}{biosample_id} ? 'IMS does not export a biosample id for this cell line'
                        : $line_hash->{biosample}{id} && $line_hash->{IMS}{biosample_id} ne $line_hash->{biosample}{id} ? 'The Biosample ID in IMS does not match the BioSamples database'
                        : $line_hash->{hESCreg}{biosample_id} && $line_hash->{hESCreg}{biosample_id} ne $line_hash->{IMS}{biosample_id} ? 'The Biosample ID in IMS does not match the BioSample ID in hESCreg'
                        : '';
  my $ims_donor_biosample_error = ! $line_hash->{IMS}{donor_biosample_id} ? 'IMS does not export a donor biosample id for this cell line'
                        : $line_hash->{biosample}{batch_donor_link}{id} && $line_hash->{biosample}{batch_donor_link}{id} ne $line_hash->{IMS}{donor_biosample_id} ? 'The donor Biosample ID in IMS does not match the BioSamples database'
                        : '';
  my $hescreg_name_error = ! $line_hash->{hESCreg}{name} ? 'hPSCreg does not export any name for this cell line'
                        : $line_hash->{IMS}{name} && $line_hash->{IMS}{name} ne $line_hash->{hESCreg}{name} ? 'hPSCreg name does not match the name in IMS'
                        : '';
  my $hescreg_biosample_error = ! $line_hash->{hESCreg}{biosample_id} ? 'hPSCreg does not export a biosample id for this cell line'
                        : $line_hash->{biosample}{id} && $line_hash->{hESCreg}{biosample_id} ne $line_hash->{biosample}{id} ? 'The Biosample ID in hPSCreg does not match the BioSamples database'
                        : $line_hash->{IMS}{biosample_id} && $line_hash->{IMS}{biosample_id} ne $line_hash->{hESCreg}{biosample_id} ? 'The Biosample ID in hPSCreg does not match the BioSample ID in IMS'
                        : '';
  my $hescreg_donor_biosample_error = ! $line_hash->{hESCreg}{donor_biosample_id} ? 'hPSCreg does not export a donor biosample id for this cell line'
                        : $line_hash->{biosample}{batch_donor_link}{id} && $line_hash->{biosample}{batch_donor_link}{id} ne $line_hash->{hESCreg}{donor_biosample_id} ? 'The donor Biosample ID in hPSCreg does not match the BioSamples database'
                        : '';
  my $biosample_id_error = !$line_hash->{biosample}{id} && !$line_hash->{IMS}{biosample_id} && !$line_hash->{hESCreg}{biosample_id} ? 'BioSample id is not known'
                        : $line_hash->{biosample}{exported}{error} ? 'BioSamples does not export the cell line with this ID' : '';

  $line_hash->{IMS}{name} = {val => $line_hash->{IMS}{name}, error => $ims_name_error ? 1:0, error_string => $ims_name_error};
  $line_hash->{IMS}{biosample_id} = {val => $line_hash->{IMS}{biosample_id}, error => $ims_biosample_error ? 1:0, error_string => $ims_biosample_error};
  $line_hash->{IMS}{donor_biosample_id} = {val => $line_hash->{IMS}{donor_biosample_id}, error => $ims_donor_biosample_error ? 1:0, error_string => $ims_donor_biosample_error};
  $line_hash->{hESCreg}{name} = {val => $line_hash->{hESCreg}{name}, error => $hescreg_name_error ? 1 : 0, error_string => $hescreg_name_error};
  $line_hash->{hESCreg}{biosample_id} = {val => $line_hash->{hESCreg}{biosample_id}, error => $hescreg_biosample_error ? 1:0, error_string => $hescreg_biosample_error};
  $line_hash->{hESCreg}{donor_biosample_id} = {val => $line_hash->{hESCreg}{donor_biosample_id}, error => $hescreg_donor_biosample_error ? 1:0, error_string => $hescreg_donor_biosample_error};
  $line_hash->{biosample}{id} = {val => $line_hash->{biosample}{id}, error => $biosample_id_error ? 1 : 0, error_string => $biosample_id_error};
  $line_hash->{biosample}{batch_line_link}{error_string} = $line_hash->{biosample}{batch_line_link}{error} ? 'At least one batch has inconsistent or missing links to the cell line' : '';
  $line_hash->{biosample}{batch_donor_link}{error_string} = $line_hash->{biosample}{batch_donor_link}{error} ? 'At least one batch has inconsistent or missing links to the donor' : '';
  $line_hash->{consensus}{donor_biosample}{error} = $line_hash->{hESCreg}{donor_biosample_id}{error} ? 1
                                                    : $line_hash->{IMS}{donor_biosample_id}{error} ? 1
                                                    : ! $line_hash->{donor_biosample}{exported} ? 1
                                                    : 0;

  my %alternate_names;
  foreach my $alternate_name (grep {$_ && $_ ne $line_hash->{consensus}{name}{val} && $_ !~ /SAM[END][AG]?[0-9]+/}
        @{$line_hash->{IMS}{alternate_names}}, $line_hash->{IMS}{name}{val},
        @{$line_hash->{hESCreg}{alternate_names}}, $line_hash->{hESCreg}{name}{val},
        $line_hash->{biosample}{name}) {
    $alternate_names{$alternate_name} = 1;
  }
  $line_hash->{consensus}{alternate_names} = join(' / ', keys %alternate_names);
  $line_hash->{IMS}{alternate_names} = join(' / ', @{$line_hash->{IMS}{alternate_names}});
  $line_hash->{hESCreg}{alternate_names} = join(' / ', @{$line_hash->{hESCreg}{alternate_names}});

  $line_hash->{tests} = \%tests;
};
$output{lines} = [sort {$a->{consensus}{name}{error} <=> $b->{consensus}{name}{error} || $a->{consensus}{name}{val} cmp $b->{consensus}{name}{val} || $a->{consensus}{alternate_names} cmp $b->{consensus}{alternate_names}} @{$output{lines}}];

$output{count} = scalar @{$output{lines}};
$output{date} = scalar localtime();

#TODO reactivate when done
#print JSON::encode_json(\%output);
