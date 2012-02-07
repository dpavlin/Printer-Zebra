#!/usr/bin/perl
use warnings;
use strict;
use autodie;

# sudo apt-get install librsvg2-bin netpbm

my $size  = $ENV{SIZE}  || '105x40';
my $width = $ENV{WIDTH} || 832;

my $args = join(' ', @ARGV);
die "usage: $0 1301272944 callnumber > label.pbm\n" unless $args;

my ( $barcode, $call1, $call2, $call3, $call4 ) = split(/\s+/, $args, 5);

open(my $from, '<',  "templates/$size.svg");
open(my $to,   '|-', "rsvg-convert --width=$width --format=png --background-color=white | pngtopnm | pnmdepth 2");
while(<$from>) {
	no warnings 'uninitialized';
	s/1301272944/$barcode/gs && warn "# barcode $barcode\n";
	s/##call1##/$call1/gs    && warn "# 1: $call1\n";
	s/##call2##/$call2/gs    && warn "# 2: $call2\n";
	s/##call3##/$call3/gs    && warn "# 3: $call3\n";
	s/##call4##/$call4/gs    && warn "# 4: $call4\n";

	print $to $_;
}
close($from);
close($to);

