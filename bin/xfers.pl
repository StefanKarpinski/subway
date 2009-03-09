#!/usr/bin/env perl

use strict;
use warnings;

use constant HOURS_PER_DAY => 1440;
use constant FEET_PER_MILE => 5280;

our $base_change_time = 1;
our $minutes_per_mile = 9;
our $transfer_window = 20;
our $max_stop_time = 1664; # could be queried

our $feet_per_minute = FEET_PER_MILE/$minutes_per_mile;
our $walk_query = <<PSQL;
	copy (
		select
			code_a as arrive_code,
			code_b as depart_code,
			pessimistic/$feet_per_minute,
			same_complex
		from walks
		where pessimistic/$feet_per_minute <= $transfer_window
	) to stdout csv;
PSQL

our %walks;
open WALK_TIMES, "psql -c '$walk_query' |" or die $!;
while (<WALK_TIMES>) {
	chomp;
	my ($arrive_code,$depart_code,$time,$same_complex) = split /,/;
	$same_complex = $same_complex eq 't' ? 1 : 0;
	$walks{$arrive_code,$depart_code} = {
		time => $time,
		same_complex => $same_complex
	};
}
close WALK_TIMES;

our $stops_query = <<PSQL;
	create temp view stop_data as
		select route, trip, code, time, type
	from stops join trips using (trip);
	copy (
		select * from (
				select route, trip, code, time, type from stop_data union
				select route, trip, code, time + @{[HOURS_PER_DAY]}, type from stop_data
					where time <= @{[$max_stop_time - HOURS_PER_DAY + $transfer_window]}
		) x order by time
	) to stdout csv;
PSQL

use constant ROUTE => 0;
use constant TRIP  => 1;
use constant CODE  => 2;
use constant TIME  => 3;

our @arrivals;
our %paired;
our %seen;

open STOPS, "psql -c '$stops_query' |" or die $!;
while (<STOPS>) {
	chomp;
	my ($route,$trip,$code,$time,$type) = split /,/;
	if ($type eq 'A' or $type eq 'T') {
		push @arrivals, [$route,$trip,$code,$time];
	}
	if ($type eq 'D' or $type eq 'T') {
		while (@arrivals and $time - $arrivals[0][TIME] >= $transfer_window) {
			my $arrival = shift @arrivals;
			delete $paired{$arrival};
		}
		for my $arrival (@arrivals) {
			next if $paired{$arrival}{$route};
			my @arrival = @{$arrival};
			next unless exists $walks{$arrival[CODE],$code};
			next if $seen{$arrival[TRIP],$trip,$arrival[CODE],$code};
			next if $arrival[ROUTE] eq $route and $arrival[TRIP] ne $trip;
			my $walk_time = $walks{$arrival[CODE],$code}{time};
			next unless
				$arrival[TRIP] eq $trip or
				$arrival[TIME] + $base_change_time + $walk_time < $time;
			my $xfer_type =
				$arrival[TRIP] eq $trip ? 'dwell' :
				$arrival[CODE] eq $code ? 'station' :
				$walks{$arrival[CODE],$code}{same_complex} ? 'complex' : 'external';
			print join(",",
				$arrival[TRIP],  $trip,
				$arrival[ROUTE], $route,
				$arrival[CODE],  $code,
				$xfer_type,
				$time - $arrival[TIME]
			), "\n";
			$seen{$arrival[TRIP],$trip,$arrival[CODE],$code}++;
			$paired{$arrival}{$route}++;
		}
	}
}
close STOPS;
