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
  my ($self) = @_;
  my @lines;
  my $url_path = 'api/v0/cell-lines/?format=json';
  while ($url_path) {
    my $json = $self->query_api($url_path);
    push(@lines, @{$json->{objects}});
    $url_path = $json->{meta}{next};
  }
  return {objects=>\@lines};
}

sub query_api {
  my ($self, $url_path) = @_;
  my $response = $self->ua->get(sprintf('https://%s/%s', $self->base_url, $url_path));
  die $response->status_line if $response->is_error;
  return decode_json($response->content);
}


1;
