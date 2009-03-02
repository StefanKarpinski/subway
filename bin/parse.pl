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
	$x = length($_) ? qq['$x'] : undef;
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
	my $mins = $1/100;
	$x = "interval '$mins minutes'"
}

sub insert_into {
	my ($table,%data) = @_;
	my @fields = sort keys %data;
	my @values = @data{@fields};
	my $fields = join ',', @fields;
	my $values = join ',', map {defined($_) ? $_ : "NULL"} @values;
	print "insert into $table ($fields) values ($values);\n";
}

# parsing subroutines

our $line;
our $service;
our $trip_id = 0;

sub timetable {
	$line = string parse 4;
	$service = string parse 2;
}

sub geography {
	my $code = string parse 8;
	my $short = string parse 8;
	my $long = string parse 33;
	my $x = integer parse 6;
	my $y = integer parse 6;
	my $coords = $x && $y ? qq['($x,$y)'] : undef;
	insert_into "stations",
		line	 => $line,
		code	 => $code,
		short  => $short,
		long	 => $long,
		coords => $coords;
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
	insert_into "trips",
		id		    => ++$trip_id,
		line			=> $line,
		service   => $service,
		orig_code	=> $orig_code,
		orig_time	=> $orig_time,
		dest_code	=> $dest_code,
		dest_time	=> $dest_time,
		direction	=> $direction,
		trip_line => $trip_line;
}

sub event {
	my $code = string parse 8;
	my $track = string parse 2;
	my $time = timeval parse 8;
	my $type = string parse 2;
	my $stop = string parse 1;
	my $timepoint = string parse 1;
	$stop = $stop eq 'S' ? 'true' : 'false';
	$timepoint = $timepoint eq 'Y' ? 'true' : 'false';
	insert_into "stops",
		trip_id		=> $trip_id,
		code			=> $code,
		track			=> $track,
		time			=> $time,
		type			=> $type,
		stop			=> $stop,
		timepoint	=> $timepoint;
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
