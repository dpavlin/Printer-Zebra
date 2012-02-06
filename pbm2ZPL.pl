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
my $size = <$fh>;
while ( $size =~ m/^#/ ) { $size = <$fh> }; # skip comments
chomp $size;
my ( $w, $h ) = split(/ /,$size,$2);
warn "WARNING: width of $pnm_file not 832 but $w !\n" if $w != 832;
local $/ = undef;
my $bitmap = <$fh>;


print '^XA';
printf '~TA%03d', 0; # tear-off
print '~JSN'; # sensor detect N = normal, 90%
print '^LT18'; # label top -120 .. 120
print '^MNW'; # media tracking N = continuous Y/W = web sensing M = mark sensing
print '^MTD'; # media type T = termal D = direct (ribbon!)
print '^PON'; # print orientation N = normal I = invert
print '^PMN'; # print mirror Y/N
print '^LH0,0'; # label home x,y
print '^JMA'; # dots/mm A = 24/12/8/6 B = 12/6/4/3
print '^PR4,4'; # print,slew,backfeed speed in inch/s 2 .. 12 [default: 2,6,2]
print '^MD13'; # media darkness -30 .. 30 / XiIIIPlus 0..30/0.1 increments
print '^JUS'; # configuration update F = factory default R = recall S = save
print '^LRN'; # label reverse Y/N
print '^CI0'; # change international font 0..255
print "^XZ\r\n";

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

print '^XA';
print '^MMT'; # print mode,prepeel T=tear-off P=peel-off R=rewind A=applicator C=cutter, Y/N
printf '^LL%d', $h; # label length FIXME ignore empty bottom
printf '^PW%d', $w; # print width
print '^LS0'; # label shift -9999..9999
printf '^FT%d,%d', 0, $h; # field typeset x,y graphic origin is bottom-left
print '^XG000.GRF,1,1^FS'; # recall grapmic source/name,magnification_x,magnification_y
print '^PQ1,0,1,Y'; # print quantity total,pause/cut,replicates,no_pause
print "^XZ\r\n";

print '^XA';
print '^ID000.GRF^FS'; # object delete
print "^XZ\r\n";

