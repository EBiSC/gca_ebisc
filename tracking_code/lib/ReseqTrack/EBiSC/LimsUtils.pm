use strict;
use warnings;

package ReseqTrack::EBiSC::LimsUtils;
use JSON;
use ReseqTrack::EBiSC::BioSampleUtils;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(find_batches);

our $api_base = '/homes/ebiscdcc/public_html/api';

sub read_json {
  my ($file) = @_;
  local $/;
  open my $fh, '<', $file or die "could not open $file: $!";
  my $json = <$fh>;
  return decode_json($json);
}

sub read_batch_list_json {
  return read_json("$api_base/batch.json");
}

sub read_batch_json {
  my ($cell_line, $batch) = @_;
  return read_json("$api_base/batch/$cell_line/$batch.json");
}

sub find_batches {
  my @batches;
  my $batch_list = read_batch_list_json();
  foreach my $batch_hash (@{$batch_list->{data}}) {
    push(@batches, read_batch_json($batch_hash->{cell_line}, $batch_hash->{batch_id})->{data});
  }
  return \@batches;
}

sub find_correct_line_hash {
  my ($lims_batch_hash, $tracking_hash) = @_;
  if (my $batch_id = $lims_batch_hash->{biosamples_batch_id}) {
    my @possibles;
    LINE:
    while (my ($key, $line_hash) = each %$tracking_hash) {
      next LINE if ! $line_hash->{biosample}{batches};
      next LINE if ! scalar grep {$_ eq $batch_id} @{$line_hash->{biosample}{batches}};
      push(@possibles, $line_hash);
    }
    return $possibles[0] if scalar @possibles == 1;
    foreach my $possible (@possibles) {
      return $possible if $possible->{hESCreg}{name} && $possible->{hESCreg}{name} eq $lims_batch_hash->{cell_line};
      return $possible if $possible->{IMS}{name} && $possible->{IMS}{name} eq $lims_batch_hash->{cell_line};
      return $possible if $possible->{biosample}{name} && $possible->{biosample}{name} eq $lims_batch_hash->{cell_line};
    }
    return $possibles[0] if scalar @possibles > 0;
  }

  while (my ($key, $line_hash) = each %$tracking_hash) {
    return $line_hash if $line_hash->{hESCreg}{name} && $line_hash->{hESCreg}{name} eq $lims_batch_hash->{cell_line};
    return $line_hash if $line_hash->{IMS}{name} && $line_hash->{IMS}{name} eq $lims_batch_hash->{cell_line};
    return $line_hash if $line_hash->{biosample}{name} && $line_hash->{biosample}{name} eq $lims_batch_hash->{cell_line};
  }
  return undef;
}

sub list_missing_data {
  my ($batch) = @_;
  my @missing;
  push(@missing, 'certificate of analysis') if ! $batch->{certificate_of_analysis};
  CC:
  foreach my $item (qw(CO2_concentration O2_concentration matrix medium passage_method temperature)) {
    push(@missing, 'culture conditions') if ! $batch->{culture_conditions}{$item};
    last CC;
  }
  push(@missing, 'ecacc catalogue number') if ! $batch->{ecacc_cat_no};
  push(@missing, 'batch id') if ! $batch->{batch_id};
  push(@missing, 'biosamples_batch_id') if ! $batch->{biosamples_batch_id};
  return \@missing;
}

1;
