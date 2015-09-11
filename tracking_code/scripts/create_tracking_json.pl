#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use ReseqTrack::EBiSC::BioSampleUtils;
use ReseqTrack::EBiSC::hESCreg;
use ReseqTrack::EBiSC::IMS;
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
  $discovered{$biosample_hash->{line}->id}{biosample} = {
    id => $biosample_hash->{line}->id,
    exported => {error => 0},
    name => $line_name,
    batch_donor_link => {
                id => $biosample_hash->{donor_id},
                error => $biosample_hash->{batches} - $biosample_hash->{batch_donor_links},
          },
    batch_line_link => {error => $biosample_hash->{batches} - $biosample_hash->{batch_line_links}},
    };
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
  };

  if ($biosample_id && !${$line_output}->{hESCreg} && $discovered_no_biosample{$line->{name}}) {
      ${$line_output}->{hESCreg} = $discovered_no_biosample{$line->{name}}{hESCreg};
      delete $discovered_no_biosample{$line->{name}};
  }
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

  if (! $line_hash->{biosample}) {
    if (my $biosample = BioSD::fetch_sample($biosample_id)) {
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
  my $name = List::Util::first {$_ && $_ =~ /[A-Z]{2,5}i[A-Z0-9]{3}-[A-Z](-[A-Z0-9])?/ } ($line_hash->{hESCreg}{name}, $line_hash->{IMS}{name});
  $line_hash->{consensus}{name} = {val => $name || '', error => $name ? 0 : 1,
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
                                  : $line_hash->{biosample}{exported}{error}  || !$line_hash->{biosample}{id} ? 'cannot test'
                                  : $line_hash->{biosample}{id} eq $line_hash->{IMS}{biosample_id} ? 'pass' : 'fail',
    'biosample id in hPSCreg consistent with BioSamples database (where both have an id)' => $line_hash->{hESCreg}{exported}{error}  || !$line_hash->{hESCreg}{biosample_id} ? 'cannot test'
                                  : $line_hash->{biosample}{exported}{error}  || !$line_hash->{biosample}{id} ? 'cannot test'
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
    'Biosamples exports the donor (where donor id is known)' => !$line_hash->{hESCreg}{donor_biosample_id}  && !$line_hash->{IMS}{donor_biosample_id} && $line_hash->{biosample}{batch_donor_link}{error} ? 'cannot test'
                                  : $line_hash->{donor_biosample}{exported}{error} ? 'fail' : 'pass',
    'Biosamples batches have explicit link to the donor' => !$line_hash->{biosample}{exported}  ? 'cannot test'
                                  : $line_hash->{biosample}{batch_donor_link}{error} ? 'fail' : 'pass',
    'Biosamples batches have explicit link to the cell line' => !$line_hash->{biosample}{exported}  ? 'cannot test'
                                  : $line_hash->{biosample}{batch_line_link}{error} ? 'fail' : 'pass',

  );

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
  my $biosample_error = ! $line_hash->{biosample}{id} ? 'BioSamples does not export the cell line with this ID'
                        : $line_hash->{biosample}{batch_line_link}{error} ? 'A BioSamples batch is missing explicit link to the cell line'
                        : $line_hash->{biosample}{batch_donor_link}{error} ? 'A BioSamples batch is missing explicit link to the donor'
                        : '';

  $line_hash->{IMS}{name} = {val => $line_hash->{IMS}{name}, error => $ims_name_error ? 1:0, error_string => $ims_name_error};
  $line_hash->{IMS}{biosample_id} = {val => $line_hash->{IMS}{biosample_id}, error => $ims_biosample_error ? 1:0, error_string => $ims_biosample_error};
  $line_hash->{IMS}{donor_biosample_id} = {val => $line_hash->{IMS}{donor_biosample_id}, error => $ims_donor_biosample_error ? 1:0, error_string => $ims_donor_biosample_error};
  $line_hash->{hESCreg}{name} = {val => $line_hash->{hESCreg}{name}, error => $hescreg_name_error ? 1 : 0, error_string => $hescreg_name_error};
  $line_hash->{hESCreg}{biosample_id} = {val => $line_hash->{hESCreg}{biosample_id}, error => $hescreg_biosample_error ? 1:0, error_string => $hescreg_biosample_error};
  $line_hash->{hESCreg}{donor_biosample_id} = {val => $line_hash->{hESCreg}{donor_biosample_id}, error => $hescreg_donor_biosample_error ? 1:0, error_string => $hescreg_donor_biosample_error};
  $line_hash->{biosample}{id} = {val => $line_hash->{biosample}{id}, error => $biosample_error ? 1 : 0, error_string => $biosample_error};
  $line_hash->{biosample}{batch_line_link}{error_string} = $line_hash->{biosample}{batch_line_link}{error} ? 'Not all batches have an explicit link to the cell line' : '';
  $line_hash->{biosample}{batch_donor_link}{error_string} = $line_hash->{biosample}{batch_donor_link}{error} ? 'Not all batches have an explicit link to the donor' : '';

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

print JSON::encode_json(\%output);
