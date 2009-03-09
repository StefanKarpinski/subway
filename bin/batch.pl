#!/usr/bin/env perl

use strict;
use warnings;

our @lines;

sub flush {
	open OUT, "|-", @ARGV or die $!;
	print OUT @lines;
	@lines = ();
	close OUT;
}

while (<STDIN>) {
	push @lines, $_;
	flush if @lines >= 100000;
}
flush if @lines;
