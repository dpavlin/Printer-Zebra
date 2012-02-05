#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use Data::Dump qw(dump);

# DG compression is documented in ZPL II Programming Guide Volume Two, page 71-72

my $compress = $ENV{COMPRESS} || 1;

my $pnm_file = shift @ARGV || die "usage: $0 print.pnm";

open(my $fh, '<', $pnm_file);
my $p4 = <$fh>; chomp $p4;
die "no P4 header in [$p4] from $pnm_file" unless $p4 eq 'P4';
my $size = <$fh>; chomp $size;
my ( $w, $h ) = split(/ /,$size,$2);
warn "WARNING: width of $pnm_file not 832 but $w !\n" if $w != 832;
local $/ = undef;
my $bitmap = <$fh>;


print "^XA~TA000~JSN^LT18^MNW^MTD^PON^PMN^LH0,0^JMA^PR4,4^MD13^JUS^LRN^CI0^XZ";

printf "~DG000.GRF,%d,%d,\r\n", $w / 8 * $h, $w / 8;

my $last_line = '';

sub zpl_compress {
	my $compress = shift;
	my $repeat = length($compress);
	my $out;
	while ( $repeat >= 400 ) {
		$out .= 'z';
		$repeat -= 400;
	}
	if ( $repeat >= 20 ) {
		$out .= chr( ord('f') + ( $repeat / 20 ) );
		$repeat %= 20;
	}
	if ( $repeat > 0 ) {
		$out .= chr( ord('F') + $repeat );
	}
	$out .= substr($compress,0,1); # char
	warn "## zpl_compress $repeat = $compress -> $out\n";
	return $out;
}

foreach my $y ( 0 .. $h - 1 ) {
	my $line = substr( $bitmap, $y * ( $w / 8 ), $w / 8 );
	if ( $line eq $last_line ) {
		print ":" && warn "# $y repeat previous line\n";
	} else {
		my $hex = unpack('H*', $line);
		if ( $compress ) {
#			$last_line = $line;
			$hex =~ s/0+$/,/  && warn "# $y fill 0 to right\n";
			$hex =~ s/F+$/!/i && warn "# $y fill 1 to right\n";
			$hex =~ s/((.)\2+)/zpl_compress($1)/egs;
		}
		print $hex;
	}
}

print "^XA\r\n^MMT\r\n^LL0328\r\n^PW831\r\n^LS0\r\n^FT0,352^XG000.GRF,1,1^FS\r\n^PQ1,0,1,Y^XZ\r\n^XA^ID000.GRF^FS^XZ";
