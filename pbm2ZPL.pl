#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use Data::Dump qw(dump);

my $pnm_file = shift @ARGV || die "usage: $0 print.pnm";

open(my $fh, '<', $pnm_file);
my $p4 = <$fh>; chomp $p4;
die "no P4 header in [$p4] from $pnm_file" unless $p4 eq 'P4';
my $size = <$fh>; chomp $size;
my ( $w, $h ) = split(/ /,$size,$2);
warn "WARNING: width of $pnm_file not 832!\n" if $w != 832;
local $/ = undef;
my $bitmap = <$fh>;


print "^XA~TA000~JSN^LT18^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4^MD13^JUS^LRN^CI0^XZ";

printf "~DG000.GRF,%d,%d,\r\n", $w / 8 * $h, $w / 8;

foreach my $y ( 0 .. $h - 1 ) {
	my $line = substr( $bitmap, $y * ( $w / 8 ), $w / 8 );
	print unpack('H*', $line);
}

print "^^XA\r\n^MMT\r\n^LL0328\r\n^PW831\r\n^LS0\r\n^FT0,352^XG000.GRF,1,1^FS\r\n^PQ1,0,1,Y^XZ\r\n^XA^ID000.GRF^FS^XZ";
