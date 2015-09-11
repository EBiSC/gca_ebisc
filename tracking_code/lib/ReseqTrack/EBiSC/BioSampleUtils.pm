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

sub find_lines {
  return $cached_lines if defined $cached_lines;
  my %lines;
  BATCH:
  foreach my $batch (@{find_batches()}) {
    my ($line, $donor_id, $line_name);
    my ( $batch_donor_link, $batch_line_link) = (0,0);
    if ($batch->property('origin cell line')) {
      $batch_line_link = 1;
      my $line_id = $batch->property('origin cell line')->values->[0];
      $line = BioSD::fetch_sample($line_id);
      next BATCH if !$line;
      ($line_name) = $line->property('Sample Name')->values->[0];
      if (my $prop = $batch->property('origin donor')) {
        $batch_donor_link = 1;
        $donor_id = $prop->values->[0];
      }
    }
    else {
      my ($vial) = @{$batch->search_for_samples('vial')};
      next BATCH if !$vial;
      ($line_name) = $vial->property('Sample Name')->values->[0] =~ /(\S+) vial *\d+/;
      next BATCH if !$line_name;
      DERIVED_FROM:
      while(1) {
        ($line) = @{$vial->derived_from()};
        next BATCH if !$line;
        last DERIVED_FROM if !$line->property('batch');
        $vial = $line;
      }
    }
    $lines{$line_name} ||= {batch_donor_links => 0, batch_line_links => 0, batches => 0};
    $lines{$line_name}{line} ||= $line;
    $lines{$line_name}{donor_id} ||= $donor_id;
    $lines{$line_name}{batches} += 1;
    $lines{$line_name}{batch_donor_links} += $batch_donor_link;
    $lines{$line_name}{batch_line_links} += $batch_line_link;
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
