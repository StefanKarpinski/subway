#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use IO::Handle;

# helper subroutines

sub parse {
	my $re = shift;
	$re = qr/(.{$re})/ if ref($re) ne 'Regexp';
	s/^$re// or croak "Failed to parse '$_'";
	return $1;
}

sub string {
	my $x = shift;
	$x =~ s/[[:cntrl:]]//g;
	$x =~ s/^\s+//;
	$x =~ s/\s+$//;
	$x =~ s/\s+/ /g;
	$x = length($x) ? $x : undef;
}
sub integer {
	my $x = shift;
	$x =~ /^\s*([-+]?\s*\d*)\s*$/ or croak "Invalid integer: $x";
	$x = length $1 ? int $1 : undef;
}
sub timeval {
	my $x = shift;
	$x =~ /^\s*$/ and return undef;
	$x =~ /^\s*([-+]?\s*\d+)\s*$/ or croak "Invalid time value: $x";
	$x = $x/100;
}

sub print_record {
	my $file = shift;
	my @data = map { defined($_) ? $_ : "NULL" } @_;
	$file->print( join("\t", @data), "\n");
}

# parsing subroutines

our $line;
our $service;
our $trip = 0;
our %codes;

open our $stations, ">data/stations_rtif.tab" or croak $!;
open our $trips, ">data/trips.tab" or croak $!;
open our $stops, ">data/stops.tab" or croak $!;

$stations->autoflush(1);
$trips->autoflush(1);
$stops->autoflush(0);

sub timetable {
	$line = string parse 4;
	$service = string parse 2;
}

sub geography {
	my $code = string parse 8;
	return if $codes{$code}++;
	my $short = string parse 8;
	my $long = string parse 33;
	my $x = integer parse 6;
	my $y = integer parse 6;
	print_record $stations,
		$line, $code,	$short,	$long, $x, $y;
}

sub applicability { }

sub trip {
	my $orig_code = string parse 8;
	my $orig_time = timeval parse 8;
	my $direction = string parse 2;
	my $type = integer parse 2;
	return unless $type == 1; # revenue
	my $dest_code = string parse 8;
	my $dest_time = timeval parse 8;
	parse 10+6+12; # skip fields
	my $trip_line = string parse 4;
	print_record $trips,
		++$trip,	$line, $service, $direction,
		$orig_code,	$orig_time,	$dest_code,	$dest_time,
		$trip_line;
}

sub event {
	my $code = string parse 8;
	my $track = string parse 2;
	my $time = timeval parse 8;
	my $type = string parse 2;
	my $stop = string parse 1;
  return unless $stop eq 'S';
	my $timepoint = string parse 1;
	$timepoint = $timepoint eq 'Y' ? 't' : 'f';
	print_record $stops,
		$trip,	$code, $track, $time,	$type, $timepoint;
}

# main parsing loop

while (<>) {
	chomp;
	my $record_type = integer parse 2;
	timetable     , next if $record_type == 10;
	geography     , next if $record_type == 13;
	applicability , next if $record_type == 17;
	trip          , next if $record_type == 20;
	event         , next if $record_type == 30;
}
