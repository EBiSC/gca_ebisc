#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use File::Find qw(find);
use JSON qw();

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
my @tests_totalled_fail;
my @tests_totalled_pass;
my %calender_tests_totalled;
foreach my $filedate (sort keys(%oneperday_files)) {
	open my $IN, '<', $oneperday_files{$filedate}[1] or die "could not open $oneperday_files{$filedate}[1] $!";
	my @lines = <$IN>;
	close $IN;
	my $tests = JSON::decode_json(join('', @lines));
	foreach my $test (@{$tests->{tests}}) {
		my $description;
		my $fail = 0;
		while ( my ($key, $value) = each(%$test) ) {
			 if ($key eq "description"){
			 	$description = $value;
			 }
			 if ($key eq "fail"){
			 	$fail = $value;
			 }
		}
		$all_tests{$description}{$filedate} = {'term' => &viewable_filedate($filedate), 'count' => $fail};
	}
	my $totalfail = 0;
	my $totalpass = 0;
	while (my ($key, $val) = each %{$tests->{tests_totalled}}) {
		if ($key eq "fail"){
		 	$totalfail = $val;
		}
		if ($key eq "pass"){
		 	$totalpass = $val;
		}
	}
	
	push(@tests_totalled_fail, {'term' => &viewable_filedate($filedate), 'count' => $totalfail});
	push(@tests_totalled_pass, {'term' => &viewable_filedate($filedate), 'count' => $totalpass});
	my @last_30_days_fail = (30 >= @tests_totalled_fail) ? @tests_totalled_fail : @tests_totalled_fail[30..-1];
	my @last_30_days_pass = (30 >= @tests_totalled_pass) ? @tests_totalled_pass : @tests_totalled_pass[30..-1];
	$calender_tests_totalled{'thirty_days'}={fail => \@last_30_days_fail, pass => \@last_30_days_pass};
}

print JSON::encode_json({testhistory => \%all_tests, tests_total_history => \%calender_tests_totalled});

sub viewable_filedate{
	#my $viewable_filedate = substr($_[0], 6, 2).'-'.substr($_[0], 4, 2).'-'.substr($_[0], 0, 4);
	#  No year
	my $viewable_filedate = substr($_[0], 6, 2).'-'.substr($_[0], 4, 2)
}