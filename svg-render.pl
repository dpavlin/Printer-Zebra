#!/usr/bin/perl
use warnings;
use strict;
use autodie;

# 5166 px = 1000 dpi

my $size = $ENV{SIZE} || '105x40';

my $w = 832;

my $density = $w / 5166 * 1000;
warn "# density = $density\n";

my $args = join(' ', @ARGV);
die "usage: $0 1301272944 callnumber\n" unless $args;

my ( $barcode, $call1, $call2, $call3, $call4 ) = split(/\s+/, $args, 5);

my $pbm = "/tmp/$barcode.pbm";

open(my $from, '<',  "templates/$size.svg");
open(my $to,   '|-', "convert -units PixelsPerInch -density $density - $pbm");
while(<$from>) {
	s/1301272944/$barcode/gs && warn "# barcode $barcode\n";
	s/##call1##/$call1/gs    && warn "# 1: $call1\n";
	s/##call2##/$call2/gs    && warn "# 2: $call2\n";
	s/##call3##/$call3/gs    && warn "# 3: $call3\n";
	s/##call4##/$call4/gs    && warn "# 4: $call4\n";

	print $to $_;
}
close($from);
close($to);

warn "$pbm ", -s $pbm, " bytes\n";


