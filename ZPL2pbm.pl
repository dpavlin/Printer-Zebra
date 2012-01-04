#!/usr/bin/perl
use warnings;
use strict;
use autodie;

my $file = shift @ARGV || die "usage: $0 dump.zpl";

open(my $in, '<', $file);

while(<$in>) {
	chomp;
	if ( /~DG(\w):(.+)/ ) {
		my ( $name, $t,$w ) = split(/,/,$2,4);

		warn "# $_ => [$name] t=$t w=$w\n";

		my $data;
		read $in, $data, $t;

		my $out;
		# ZPL decompress
		my $repeat = 1;
		foreach my $p ( 0 .. length($data) ) {
			my $c = substr($data,$p,1);
			if ( $c eq ',' ) {
				my $l = ( $w * 2 ) - length($out) % ( $w * 2 );
				$l = $w * 2 if $l == 0;
				warn "# $p ZERO-to-EOL $c [$l]\n";
				$out .= "0" x $l;
			} elsif ( $c eq ':' ) {
				$out .= length($out) > $w ? substr($out,-$w*2) : "00" x $w;
				warn "# $p :\n";
			} elsif ( $c eq 'z' ) {
				$repeat += 400;
			} elsif ( $c ge 'g' && $c le 'y' ) {
				$repeat += 20 * ( ord($c) - ord('f') );
			} elsif ( $c ge 'G' && $c le 'Y' ) {
				$repeat += ord($c) - ord('F');
			} elsif ( $c =~ m/[0-9A-F]/ ) {
				if ( $repeat ) {
					warn "# $p $repeat $c\n";
					$out .= $c x $repeat;
					$repeat = 0;
				} else {
					warn "# $p hex $c\n";
					$out .= $c;
				}
			} else {
				warn "ABORT: offset $p data [$c]";
				last;
			}

			warn "## $repeat [$c] out = ",length($out);
		}


		my $bitmap = pack('H*', $out);
		warn "# graphics of ",length($data)," bytes ZPL decompressed to ",length($out)," hex and ", length($bitmap), " bytes bitmap\n";
		my $pw = $w * 8;
		my $ph = int(length($bitmap) / $w);
		print "P4\n$pw $ph\n", substr($bitmap,0,$ph*$w);

	} else {
		warn "IGNORED: $_\n";
	}
}