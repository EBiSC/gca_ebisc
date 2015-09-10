#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use File::Find qw(find);
use JSON qw();
use Data::Dumper; #DELETE WHEN TESTING DONE

#  JSON batches located at: (DELETE ME)
#/nfs/production/reseq-info/work/ebiscdcc/tracking_json/

my $tracking_json;

GetOptions("tracking_json=s" => \$tracking_json);

my @files;
find sub {push @files, $File::Find::name if /^api_tests\.\d+/}, $tracking_json;

#  Filter file list for latest version on any particular day, avoid messy graphs
my %oneperday_files;
foreach my $file (@files) {
	my @parts = split('\.', $file);
	if ($oneperday_files{$parts[-3]}){
		if ($oneperday_files{$parts[-3]}[0] < $parts[-2]){
			$oneperday_files{$parts[-3]} = [$parts[-2], $file];
		}
   	}else{
   		$oneperday_files{$parts[-3]} = [$parts[-2], $file];
   	} 
}

#  Extract test results for each day
my %all_tests;
foreach my $filedate (keys(%oneperday_files)) {
	open my $IN, '<', $oneperday_files{$filedate}[1] or die "could not open $oneperday_files{$filedate}[1] $!";
	my @lines = <$IN>;
	close $IN;
	my $tests = JSON::decode_json(join('', @lines));
	foreach my $test (@{$tests->{tests}}) {
		my $description;
		my $pass = 0;
		my $fail = 0;
		my $cannot_test = 0;
		while ( my ($key, $value) = each(%$test) ) {
			 if ($key eq "description"){
			 	$description = $value;
			 }
			 if ($key eq "pass"){
			 	$pass = $value;
			 }
			 if ($key eq "fail"){
			 	$fail = $value;
			 }
			 if ($key eq "cannot test"){
			 	$cannot_test = $value;
			 }
		}
		$all_tests{$description}{$filedate} = {'pass' => $pass, 'fail' => $fail, 'cannot test' => $cannot_test};
	}
}

print JSON::encode_json({testhistory => \%all_tests});