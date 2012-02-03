#!/usr/bin/perl
use warnings;
use strict;

# 5166 px = 1000 dpi

my $w = 832;

my $density = $w / 5166 * 1000;
warn "# density = $density\n";

my $from = shift @ARGV || die "usage: $0 template.svg\n";

system "convert -density $density $from $from.pbm";


