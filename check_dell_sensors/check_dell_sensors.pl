#!/usr/bin/perl -T
#############################################################################
#                                                                           #
# This script was initially developed by Anstat Pty Ltd for internal use    #
# and has kindly been made available to the Open Source community for       #
# redistribution and further development under the terms of the             #
# GNU General Public License: http://www.gnu.org/licenses/gpl.html          #
#                                                                           #
#############################################################################
#                                                                           #
# This script is supplied 'as-is', in the hope that it will be useful, but  #
# neither Anstat Pty Ltd nor the authors make any warranties or guarantees  #
# as to its correct operation, including its intended function.             #
#                                                                           #
# Or in other words:                                                        #
#       Test it yourself, and make sure it works for YOU.                   #
#                                                                           #
#############################################################################
# Author: George Hansper               e-mail:  Name.Surname@anstat.com.au  #
#############################################################################

$ENV{PATH}="/sbin:/usr/sbin:/bin:/usr/bin";

use strict vars;

my $rcsid = '$Id: check_dell_sensors.pl,v 1.2 2006/10/08 22:43:40 georgeh Exp georgeh $';
my $rcslog = '
  $Log: check_dell_sensors.pl,v $
  Revision 1.2  2006/10/08 22:43:40  georgeh
  Added line to clobber BASH_ENV for taint checks (simplifies testing on the command line).

  Revision 1.1  2005/12/19 04:52:45  georgeh
  Initial revision

';

# Taint checks may fail due to the following...
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

if ( @ARGV > 0 ) {
	if( $ARGV[0] eq "-V" ) {
		print STDERR "$rcsid\n";
	} else {
		print STDERR "Nagios plugin for checking the status of Dell chassis sensors using 'omreport'\n";
		print STDERR "Requires Dell Open Manage to be installed.\n";
		print STDERR "\n";
		print STDERR "Usage:\n";
		print STDERR "\t$0 [-V]\n";
		print STDERR "\t\t-V ... print version information\n";
		print STDERR "\n";
	}
}

my ($ok,$tag,$value,$alarm);
my (%alarm,%sensor);

open(OMREPORT,"sudo omreport chassis|") || do { print "omreport: " . $! ."\n"; exit 2};

$ok="OK";
while ( <OMREPORT> ) {
	if ( $_ !~ /:/ ) {
		next;
	}
	chomp;
	($value,$tag) = split /\s*:\s*/, "$_", 2;
	if ( "$tag" =~ /^(COMPONENT|SEVERITY|)$/ ) {
		next;
	}
	if ( "$value" !~ m/Ok/i ) {
		$alarm = 1;
		$ok="ALARM: ";
		$alarm{$tag} = $alarm;
	} else {
		$alarm = 0;
	}
	($value,) = split /\s+/, "$value", 2;
	$sensor{$tag} = $value . ($alarm?"**":"");
}

print "$ok";
print join ", ", ( sort ( keys %alarm ));
print " --";
foreach $tag ( sort ( keys %sensor )) {
	print " $tag=$sensor{$tag};";
}
print "\n";

if ( $ok eq "OK" ) {
	exit 0;
} else {
	exit 2;
}

