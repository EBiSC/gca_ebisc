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

#  Filter file list for latest version on any particular day, avoids messy graphs
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


my %all_tests;
my %calender_all_tests;
my @tests_totalled_fail;
my @tests_totalled_pass;
my @tests_totalled_fail_prop;
my @tests_totalled_pass_prop;
my @tests_totalled_lines;
my %calender_tests_totalled;

#  Extract test results for each day
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
	push(@tests_totalled_fail_prop, {'term' => &viewable_filedate($filedate), 'count' => (($totalfail/($totalpass+$totalfail))*100)});
	push(@tests_totalled_pass_prop, {'term' => &viewable_filedate($filedate), 'count' => (($totalpass/($totalpass+$totalfail))*100)});
	push(@tests_totalled_lines, {'term' => &viewable_filedate($filedate), 'count' => ($totalpass+$totalfail)});
}

#  For each test, only keep last 30 days - currently not needed
#foreach my $description (sort keys(%all_tests)) {
#	if ($description eq "hPSCreg validates the cell line"){
#		my $readable_description = "hpscregvalidated";
#		my @allkeys = sort keys $all_tests{$description};
#		$calender_all_tests{$readable_description}{'thirty_days'} = [];
#		my @last_30_days_allkeys = &last_30_days(@allkeys);
#		foreach my $kept (@last_30_days_allkeys){
#			push($calender_all_tests{$readable_description}{'thirty_days'}, $all_tests{$description}{$kept});
#		} 
#	}
#}

my @last_30_days_fail = &last_30_days(@tests_totalled_fail);
my @last_30_days_pass = &last_30_days(@tests_totalled_pass);
my @last_30_days_fail_prop = &last_30_days(@tests_totalled_fail_prop);
my @last_30_days_pass_prop = &last_30_days(@tests_totalled_pass_prop);
my @last_30_days_lines = &last_30_days(@tests_totalled_lines);
$calender_tests_totalled{'raw'}={thirty_days => {fail => \@last_30_days_fail, pass => \@last_30_days_pass, total => \@last_30_days_lines}};
$calender_tests_totalled{'proportion'}={thirty_days => {fail => \@last_30_days_fail_prop, pass => \@last_30_days_pass_prop}};

#  Only include total tests
print JSON::encode_json({tests_total_history => \%calender_tests_totalled});
#  Also include all tests
#print JSON::encode_json({testhistory => \%calender_all_tests, tests_total_history => \%calender_tests_totalled});

sub viewable_filedate{
	#  No year
	my $viewable_filedate = substr($_[0], 6, 2).'-'.substr($_[0], 4, 2)
	#  With year
	#my $viewable_filedate = substr($_[0], 6, 2).'-'.substr($_[0], 4, 2).'-'.substr($_[0], 0, 4);
}
sub last_30_days{
	my @last_30_days = (30 >= @_) ? @_ : @_[30..-1];
}