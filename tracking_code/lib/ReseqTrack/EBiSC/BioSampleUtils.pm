use strict;
use warnings;

package ReseqTrack::EBiSC::BioSampleUtils;
use BioSD;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(find_batches);

my $cached_batches;
my $cached_lines;

sub find_batches {
  return $cached_batches if defined $cached_batches;
  my @batches;
  GROUP:
  foreach my $group (@{BioSD::search_for_groups('ebisc')}) {
    next GROUP if ! $group->property('Submission Title');
    next GROUP if ! scalar grep {$_ eq 'EBiSC'} @{$group->property('Submission Title')->values};
    push(@batches, $group);
  }
  $cached_batches = \@batches;
  return $cached_batches;
}

sub batch_to_linked_line {
  my ($batch) = @_;
  my $link_prop = $batch->property('origin cell line');
  return undef if !$link_prop;
  my $sample = eval{BioSD::fetch_sample($link_prop->values->[0]);};
  return $sample;
};

sub batch_to_linked_donor {
  my ($batch) = @_;
  my $link_prop = $batch->property('origin donor');
  return undef if !$link_prop;
  my $sample = eval{BioSD::fetch_sample($link_prop->values->[0]);};
  return $sample;
};

sub batch_to_derived_from_line {
  my ($batch) = @_;
  my ($line) = @{$batch->samples};
  while (1) {
    return undef if !$line;
    return $line if $line->property('Sample Name')->values->[0] !~ /vial *\d+/;
    ($line) = grep {$_->is_valid} @{$line->derived_from};
  }
}

sub batch_to_name_from_vial {
  my ($batch) = @_;
  my ($line) = @{$batch->samples};
  return undef if !$line;
  my $name = $line->property('Sample Name')->values->[0];
  $name =~ s/\s+vial *\d+\s*$//;
  return $name;
}


sub find_lines {
  return $cached_lines if defined $cached_lines;
  my %lines;
  BATCH:
  foreach my $batch (@{find_batches()}) {
    my $linked_line = batch_to_linked_line($batch);
    my $linked_donor = batch_to_linked_donor($batch);
    my $derived_from_line = batch_to_derived_from_line($batch);

    if ($linked_line && $derived_from_line && ($linked_line->id ne $derived_from_line->id)) {
      foreach my $line ($linked_line, $derived_from_line) {
        my $line_name = $line->property('Sample Name')->values->[0];
        $lines{$line_name} ||= {batch_donor_link => {}, batch_line_link => {}, name => $line_name, batches=>[]};
        $lines{$line_name}{batch_line_link}{error} = 1;
        $lines{$line_name}{batch_line_link}{error_batch} //= [];
        push(@{$lines{$line_name}{batch_line_link}{error_batch}}, $batch->id);
        if ($linked_donor) {
          $lines{$line_name}{batch_donor_link}{id} = $linked_donor->id;
          $lines{$line_name}{batch_donor_link}{error} = $linked_donor->id eq $lines{$line_name}{batch_donor_link}{id} ? ($lines{$line_name}{batch_donor_link}{error} || 0) : 1;
        }
        else {
          $lines{$line_name}{batch_donor_link}{error} = 1;
          $lines{$line_name}{batch_donor_link}{error_batch} //= [];
          push(@{$lines{$line_name}{batch_donor_link}{error_batch}}, $batch->id);
        }
        $lines{$line_name}{id} //= $line->id;
        push(@{$lines{$line_name}{batches}}, $batch->id);
      }
      next BATCH;
    }

    if ($linked_line || $derived_from_line) {
      my $line_name = $linked_line ? $linked_line->property('Sample Name')->values->[0]
                  : $derived_from_line->property('Sample Name')->values->[0];
      $lines{$line_name} ||= {batch_donor_link => {}, batch_line_link => {}, name => $line_name, batches => []};
      if (!$linked_line || !$derived_from_line) {
        $lines{$line_name}{batch_line_link}{error} = 1;
        $lines{$line_name}{batch_line_link}{error_batch} //= [];
        push(@{$lines{$line_name}{batch_line_link}{error_batch}}, $batch->id);
      }
      else {
        $lines{$line_name}{batch_line_link}{error} ||= 0;
        $lines{$line_name}{batch_line_link}{id} ||= $linked_line ? $linked_line->id : $derived_from_line->id;
      }
      if ($linked_donor) {
        $lines{$line_name}{batch_donor_link}{id} = $linked_donor->id;
        $lines{$line_name}{batch_donor_link}{error} = $linked_donor->id eq $lines{$line_name}{batch_donor_link}{id} ? ($lines{$line_name}{batch_donor_link}{error} || 0) : 1;
      }
      else {
        $lines{$line_name}{batch_donor_link}{error} = 1;
        $lines{$line_name}{batch_donor_link}{error_batch} //= [];
        push(@{$lines{$line_name}{batch_donor_link}{error_batch}}, $batch->id);
      }
      $lines{$line_name}{id} //= $linked_line ? $linked_line->id : $derived_from_line->id;
      push(@{$lines{$line_name}{batches}}, $batch->id);
      next BATCH;
    }

    if (my $line_name = batch_to_name_from_vial($batch)) {
      $lines{$line_name} ||= {batch_donor_link => {}, batch_line_link => {}, name => $line_name, batches => []};
      $lines{$line_name}{batch_line_link}{error} = 1;
      $lines{$line_name}{batch_line_link}{error_batch} //= [];
      push(@{$lines{$line_name}{batch_line_link}{error_batch}}, $batch->id);
      if ($linked_donor) {
        $lines{$line_name}{batch_donor_link}{id} = $linked_donor->id;
        $lines{$line_name}{batch_donor_link}{error} = $linked_donor->id eq $lines{$line_name}{batch_donor_link}{id} ? ($lines{$line_name}{batch_donor_link}{error} || 0) : 1;
      }
      else {
        $lines{$line_name}{batch_donor_link}{error} = 1;
        $lines{$line_name}{batch_donor_link}{error_batch} //= [];
        push(@{$lines{$line_name}{batch_donor_link}{error_batch}}, $batch->id);
      }
      push(@{$lines{$line_name}{batches}}, $batch->id);
    }
  }
  $cached_lines = \%lines;
  return $cached_lines;
}

sub count_vials {
  my %args = @_;
  my $biosample_id = $args{id};
  my $biosample = BioSD::fetch_sample($biosample_id);
  return 0 if !$biosample;
  my $count = 0;
  CHILD:
  foreach my $child (@{$biosample->derivatives}) {
    next CHILD if $child->property('Sample Name')->values->[0] !~ /vial \d+$/;
    $count += 1 + count_vials(id => $child->id);
  }
  return $count;
}

sub get_vial_name {
  my %args = @_;
  my $biosample_id = $args{id};
  my $biosample = BioSD::fetch_sample($biosample_id);
  return undef if !$biosample;
  CHILD:
  foreach my $child (@{$biosample->derivatives}) {
    if ($child->property('Sample Name')->values->[0] =~ /(\S+) vial \d+/) {
      return $1;
    }
  }
  return undef;
}

1;
