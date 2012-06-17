#!/usr/bin/perl
use warnings;
use strict;

use CGI::Carp qw(fatalsToBrowser);
use autodie;
use POSIX qw(strftime);

print "Content-type: text/html\r\n\r\n";

print qq{
<html>
<head>
<title>Zebra printers status</title>
</head>
<body>

};

foreach my $filename ( glob '/tmp/zebra/*.status' ) {
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	$atime,$mtime,$ctime,$blksize,$blocks)
		= stat($filename);

	my $date = strftime "%Y-%m-%d %H:%M:%S", localtime($mtime);



	local $/ = undef;
	open(my $fh, $filename);
	my $status = <$fh>;
	close $fh;

	my $style = '';
	$style=' style="color:#c00"' if $status =~ m/error/;

	print "<h1$style>$filename $date</h1>\n\n";
	print "<pre$style>$status</pre>\n\n";
}

print qq{
</body>
</html>
};
