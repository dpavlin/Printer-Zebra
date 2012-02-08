#!/usr/bin/perl
use warnings;
use strict;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use autodie;

my $q = CGI->new;

my $size  = $q->param('size') || '105x40';
my $width = $q->param('width')    || 832;

my $print = $q->param('print') || die "no print?";

my $ip = $q->remote_addr;
my $dir = '/srv/Printer-Zebra';

my ( $barcode, $call1, $call2, $call3, $call4 ) = split(/\s+/, $print, 5);

my $tmp = '/tmp/zebra';
mkdir $tmp unless -e $tmp;

open(my $from, '<',  "$dir/templates/$size.svg");
open(my $to,   '|-', "rsvg-convert --width=$width --format=png --background-color=white | tee $tmp/$barcode.png | pngtopnm > $tmp/$barcode.pnm");
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

system "./pbm2ZPL.pl $tmp/$barcode.pnm | rlpr --printhost=$ip --printer=zpl --windows --verbose";

if ( my $return = $q->param('return') ) {
	print $q->redirect( $q->param('return') . '&station=' . $ip );
} else {
	print "Content-type: image/png\r\n\r\n";
	local $/ = undef;
	open(my $fh, '<', "$tmp/$barcode.png");
	print <$fh>;
}

