package ReseqTrack::EBiSC::XMLUtils;
use XML::Writer;

use Exporter 'import';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(dump_xml);

sub dump_xml {
  my ($fh, $root_name, $data) = @_;

  my $writer = new XML::Writer(
    OUTPUT => $fh,
    DATA_INDENT => 4,
    CHECK_PRINT => 1,
    DATA_MODE   => 1,
  );

  $writer->xmlDecl( 'UTF-8' );
  _dump_element($writer, $root_name, $data);
  $writer->end( );

}

sub _dump_element {
  my ($writer, $name, $content) = @_;

  if (ref $content eq 'ARRAY') {
    foreach my $item (@$content) {
      _dump_element($writer, $name, $item);
    }
    return;
  }

  $writer->startTag( $name );
  if (ref $content eq 'HASH') {
    foreach my $key (sort keys %$content) {
      _dump_element($writer, $key, $content->{$key});
    }
  }
  elsif (! ref $content) {
    $writer->characters($content);
  }
  $writer->endTag( $name );
}

1;
