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
    my ($vial) = @{$batch->search_for_samples('vial 01')};
    next BATCH if !$vial;
    my ($line_name) = $vial->property('Sample Name')->values->[0] =~ /(\S+) vial 01/;
    next BATCH if !$line_name;
    my ($line) = @{$vial->derived_from()};
    next BATCH if !$line;
    $lines{$line_name} = $line;
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
