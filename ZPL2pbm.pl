#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use Data::Dump qw(dump);

# convert Zebra label printer ZPL to pbm image

my $command;
while(<DATA>) {
	chomp;
	my ( $cmd, $desc ) = split(/\s/,$_,2);
	$command->{$cmd} = $desc;
}

my $file = shift @ARGV || die "usage: $0 dump.zpl > dump.pbm";

open(my $in, '<', $file);

our $line = '';
sub slurp_line {
	$line .= <$in> unless length $line > 3;
}
slurp_line;

while( $line ) {
	$line =~ s/[\r\n]+$// && warn "## removed CR/LF\n";
	warn "# line ",dump($line),$/ if length($line) < 80 or $ENV{DEBUG};
	if ( $line =~ s/~DG(\w+:)?(.+)// ) {
		my ( $name, $t,$w ) = split(/,/,$2,4);

		warn "# ~DG$1 => [$name] t=$t w=$w\n";

		my $data = <$in>;

		my $out;
		# ZPL decompress
		my $repeat = 0;
		foreach my $p ( 0 .. length($data) - 1 ) {
			my $c = substr($data,$p,1);
			if ( $c eq ',' ) {
				my $l = ( $w * 2 ) - length($out) % ( $w * 2 );
				$l = $w * 2 if $l == 0;
				warn "# $p ZERO-to-EOL $c [$l]\n";
				$out .= "0" x $l;
			} elsif ( $c eq '!' ) {
				my $l = ( $w * 2 ) - length($out) % ( $w * 2 );
				$l = $w * 2 if $l == 0;
				warn "# $p ONE-to-EOL $c [$l]\n";
				$out .= "1" x $l;
			} elsif ( $c eq ':' ) {
				$out .= length($out) > $w ? substr($out,-$w*2) : "00" x $w;
				warn "# $p repeat last line\n";
			} elsif ( $c eq 'z' ) {
				$repeat += 400;
			} elsif ( $c ge 'g' && $c le 'y' ) {
				$repeat += 20 * ( ord($c) - ord('f') );
			} elsif ( $c ge 'G' && $c le 'Y' ) {
				$repeat += ord($c) - ord('F');
			} elsif ( $c =~ m/[0-9A-F]/i ) {
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
				$line = $c . substr($data,$p);
				slurp_line;
				last;
			}

			warn "## $repeat [$c] out = ",length($out),$/;
		}

		my $bitmap = pack('H*', $out);
		warn "# graphics of ",length($data)," bytes ZPL decompressed to ",length($out)," hex and ", length($bitmap), " bytes bitmap\n";
		my $pw = $w * 8;
		my $ph = int(length($bitmap) / $w);
		print "P4\n$pw $ph\n", substr($bitmap,0,$ph*$w);

	} elsif ( $line =~ s/^([~\^][^~\^\r\n]*)// ) {
		my $cmd = substr($1,0,3);
		if ( my $desc = $command->{$cmd} ) {
			warn "ZPL: $1\t$desc\n";
		} else {
			warn "UNKNOWN: ",dump($1),$/;
		}
		$line =~ s/^[\r\n]+// && warn "## removed CR/LF\n";
	} else {
		my $unknown = $1 if $line =~ s/^(.)//; # printer seems to ignore invalid chars
		warn "IGNORE: ",dump($unknown);
	}

	slurp_line;
}

__DATA__
^A Scalable/Bitmapped Font
^A@ Use Font Name to Call Font
^B1 Code 11 Bar Code
^B2 Interleaved 2 of 5 Bar Code
^B3 Code 39 Bar Code
^B4 Code 49 Bar Code
^B5 Planet Code bar code
^B7 PDF417 Bar Code
^B8 EAN-8 Bar Code
^B9 UPC-E Bar Code
^BA Code 93 Bar Code
^BB CODABLOCK Bar Code
^BC Code 128 Bar Code (Subsets A, B, and C)
^BD UPS MaxiCode Bar Code
^BE EAN-13 Bar Code
^BF Micro-PDF417 Bar Code
^BI Industrial 2 of 5 Bar Codes
^BJ Standard 2 of 5 Bar Code
^BK ANSI Codabar Bar Code
^BL LOGMARS Bar Code
^BM MSI Bar Code
^BO Aztec Bar Code Parameters
^BP Plessey Bar Code
^BQ QR Code Bar Code
^BR RSS (Reduced Space Symbology) Bar Code
^BS UPC/EAN Extensions
^BT TLC39 bar code
^BU UPC-A Bar Code
^BX Data Matrix Bar Code
^BY Bar Code Field Default
^BZ POSTNET Bar Code
^CC Change Carets
~CC Change Carets
^CD Change Delimiter
~CD Change Delimiter
^CF Change Alphanumeric Default Font
^CI Change International Font
^CM Change Memory Letter Designation
^CO Cache On
^CT Change Tilde
~CT Change Tilde
^CV Code Validation
^CW Font Identifier
~DB Download Bitmap Font
~DE Download Encoding
^DF Download Format
~DG Download Graphics
~DN Abort Download Graphic
~DS Download Scalable Font
~DT Download TrueType Font
~DU Download Unbounded TrueType Font
~DY Download Graphics
~EG Erase Download Graphics
^FB Field Block
^FC Field Clock (for Real-Time Clock)
^FD Field Data
^FH Field Hexadecimal Indicator
^FM Multiple Field Origin Locations
^FN Field Number
^FO Field Origin
^FP Field Parameter
^FR Field Reverse Print
^FS Field Separator
^FT Field Typeset
^FV Field Variable
^FW Field Orientation
^FX Comment
^GB Graphic Box
^GC Graphic Circle
^GD Graphic Diagonal Line
^GE Graphic Ellipse
^GF Graphic Field
^GS Graphic Symbol
~HB Battery Status
~HD Head Temperature Information
^HF Graphic Symbol
^HG Host Graphic
^HH Configuration Label Return
~HI Host Identification
~HM Host RAM Status
~HS Host Status Return
~HU Return ZebraNet Alert Configuration
^HV Host Verification
^HW Host Directory List
^HY Upload Graphics
^HZ Display Description Information
^ID Object Delete
^IL Image Load
^IM Image Move
^IS Image Save
~JA Cancel All
^JB Initialize Flash Memory
~JB Reset Optional Memory
~JC Set Media Sensor Calibration
~JD Enable Communications Diagnostics
~JE Disable Diagnostics
~JF Set Battery Condition
~JG Graphing Sensor Calibration
^JJ Set Auxiliary Port
~JL Set Label Length
^JM Set Dots per Millimeter
~JN Head Test Fatal
~JO Head Test Non fatal
~JP Pause and Cancel Format
~JR Power On Reset
^JS Sensor Select
~JS Change Backfeed Sequence
^JT Head Test Interval
^JU Configuration Update
^JW Set Ribbon Tension
~JX Cancel Current Partially Input Format
^JZ Reprint After Error
~KB Kill Battery (Battery Discharge Mode)
^KD Select Date and Time Format (for Real Time Clock)
^KL Define Language
^KN Define Printer Name
^KP Define Password
^LH Label Home
^LL Label Length
^LR Label Reverse Print
^LS Label Shift
^LT Label Top
^MC Map Clear
^MD Media Darkness
^MF Media Feed
^ML Maximum Label Length
^MM Print Mode
^MN Media Tracking
^MP Mode Protection
^MT Media Type
^MU Set Units of Measurement
^MW Modify Head Cold Warning
~NC Network Connect
^NI Network ID Number
~NR Set All Network Printers Transparent
^NS Change Networking Settings
~NT Set Currently Connected Printer Transparent
^PF Slew Given Number of Dot Rows
^PH Slew to Home Position
~PH Slew to Home Position
^PM Printing Mirror Image of Label
^PO Print Orientation
^PP Programmable Pause
~PP Programmable Pause
^PQ Print Quantity
^PR Print Rate
~PR Applicator Reprint
~PS Print Start
^PW Print Width
~RO Reset Advanced Counter
^SC Set Serial Communications
~SD Set Darkness
^SE Select Encoding
^SF Serialization Field (with a Standard ^FD String)
^SL Set Mode and Language (for Real-Time Clock)
^SN Serialization Data
^SO Set Offset (for Real-Time Clock)
^SP Start Print
^SQ Halt ZebraNet Alert
^SR Set Printhead Resistance
^SS Set Media Sensors
^ST Set Date and Time (for Real-Time Clock)
^SX Set ZebraNet Alert
^SZ Set ZPL
~TA Tear-off Adjust Position
^TO Transfer Object
~WC Print Configuration Label
^WD Print Directory Label
^XA Start Format
^XB Suppress Backfeed
^XF Recall Format
^XG Recall Graphic
^XZ End Format
^ZZ Printer Sleep
