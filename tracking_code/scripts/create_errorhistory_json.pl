#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use File::Find qw(find);
use JSON qw();
use Data::Dumper;

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
my @month_tests_totalled_fail;
my @month_tests_totalled_pass;
my @month_tests_totalled_fail_prop;
my @month_tests_totalled_pass_prop;
my @month_tests_totalled_lines;
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
	push(@month_tests_totalled_fail, {'term' => $filedate, 'count' => $totalfail});
	push(@month_tests_totalled_pass, {'term' => $filedate, 'count' => $totalpass});
	push(@month_tests_totalled_fail_prop, {'term' => $filedate, 'count' => (($totalfail/($totalpass+$totalfail))*100)});
	push(@month_tests_totalled_pass_prop, {'term' => $filedate, 'count' => (($totalpass/($totalpass+$totalfail))*100)});
	push(@month_tests_totalled_lines, {'term' => $filedate, 'count' => ($totalpass+$totalfail)});
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

my @months_fail = &month_average(@month_tests_totalled_fail);
my @months_pass = &month_average(@month_tests_totalled_pass);
my @months_fail_prop = &month_average(@month_tests_totalled_fail_prop);
my @months_pass_prop = &month_average(@month_tests_totalled_pass_prop);
my @months_lines = &month_average(@month_tests_totalled_lines);

my @last_30_days_fail = &last_30_days(@tests_totalled_fail);
my @last_30_days_pass = &last_30_days(@tests_totalled_pass);
my @last_30_days_fail_prop = &last_30_days(@tests_totalled_fail_prop);
my @last_30_days_pass_prop = &last_30_days(@tests_totalled_pass_prop);
my @last_30_days_lines = &last_30_days(@tests_totalled_lines);
$calender_tests_totalled{'raw'}={thirty_days => {fail => \@last_30_days_fail, pass => \@last_30_days_pass, total => \@last_30_days_lines}, week_average => {fail => \@months_fail, pass => \@months_pass, total => \@months_lines}};
$calender_tests_totalled{'proportion'}={thirty_days => {fail => \@last_30_days_fail_prop, pass => \@last_30_days_pass_prop}, week_average => {fail => \@months_fail_prop, pass => \@months_pass_prop}};

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
	my @last_30_days = (30 >= @_) ? @_ : @_[-30..-1];
}
sub month_average{
	my @month_avg;
	my $currentday;
	my %total;
	my %days;
	foreach my $date (@_){
		my $viewable_date = &viewable_filedate($$date{'term'});
		my ($day, $month) = split('-', $viewable_date);
		if ($day =~ '01'||$day eq '07'||$day eq '14'||$day eq '21'||$day eq '28'){
			$currentday = $$date{'term'};
			$total{$currentday}= int($$date{'count'});
			$days{$currentday}+=1;
		}else{
			$total{$currentday}= int($$date{'count'})+$total{$currentday};
			$days{$currentday}+=1;
		}
	}
	foreach my $key (sort keys %total){
		push(@month_avg, {'term' => &viewable_filedate($key), 'count' => $total{$key}/$days{$key}});
	}
	return @month_avg;
}
