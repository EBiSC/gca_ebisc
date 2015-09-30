use strict;
use warnings;

package ReseqTrack::EBiSC::hESCreg;
use namespace::autoclean;
use Moose;
use LWP::UserAgent;
use JSON qw(decode_json);

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


1;
