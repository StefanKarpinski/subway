#!/usr/bin/env perl

use strict;
use warnings;

our $batch = 10000;
our @lines;

sub flush {
	open OUT, "|-", @ARGV or die $!;
	print OUT @lines;
	@lines = ();
	close OUT;
}

while (<STDIN>) {
	push @lines, $_;
	flush if @lines >= $batch;
}
flush if @lines;
