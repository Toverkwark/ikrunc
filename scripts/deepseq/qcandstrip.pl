use Getopt::Long;

sub MatchBarcode($@);
sub ScoreTwoStrings($$);

print "qcandstrip.pl -input -output -report\n";

GetOptions(
	"input=s"  => \$InputFile,
	"output=s" => \$OutputFile,
	"report=s" => \$ReportFile,
);

if ( !$OutputFile ) {
	$OutputFile = $InputFile . ".stripped";
}

if ( !$ReportFile ) {
	$ReportFile = $InputFile . ".report.csv";
}

@Barcodes = qw(CGTGAT ACATCG GCCTAA TGGTCA CACTGT ATTGGC GATCTG TCAAGT CTGATC AAGCTA GTAGCC TACAAG);
%Results  = ();
open( INPUT, $InputFile ) or die "Input file $InputFile is not accessible.\n";
open( OUTPUT, ">", $OutputFile ) or die "Output file $OutputFile is not accessible.\n";
open( REPORT, ">", $ReportFile ) or die "Report file $ReportFile is not accessible.\n";

while ( defined( my $line = <INPUT> ) ) {
	$RecordsAnalyzed++;
	if ( !( $RecordsAnalyzed % 100000 ) ) {
		print "Analyzing record $RecordsAnalyzed\n";
	}
	$line2    = <INPUT>;
	$line3    = <INPUT>;
	$line4    = <INPUT>;
	chomp($line2);
	$sequence = $line2;

	$CriteriaMatched = 0;
	#Get the barcode as the first 6 nucleotides. See if it exists. If not, try to map it with maximally 1 nucleotide replacement and only 1 match existing.
	#if that can be found, make sure to also write the output file sequences with the mapped barcode
	$barcode = substr( $sequence, 0, 6 );
	if ( grep( /$barcode/, @Barcodes ) ) {
		$CriteriaMatched++;
		$Results{$barcode}->[0]++;
	}
	else {
		my $MatchedBarcode = MatchBarcode( $barcode, @Barcodes );
		if ($MatchedBarcode) {
			$CriteriaMatched++;
			$barcode = $MatchedBarcode;
			$Results{$barcode}->[0]++;
			$Results{$barcode}->[1]++;
			#Change the barcode in the outputfile to the one it was matched to
			$line2 = $barcode . substr($line2,6,length($line2)-6);
		}
	}

	#Try to match part of the promoter and calculate an offset based on the first match encountered for 9 nucleotides, then move on
	#Start by trying to match on the position that it should be, only if that doesn't fit, do a loop
	my $Offset = 0;
	if ( substr( $sequence, 6, 9 ) eq 'CCCTATCAG' ) {
		$CriteriaMatched++;
		$Results{$barcode}->[2]++;
	}
	else {
		for ( my $i = 0 ; $i <= length($sequence) - 6 ; $i++ ) {
			if ( substr( $sequence, 6 + $i, 9 ) eq 'CCCTATCAG' ) {
				$CriteriaMatched++;
				$Results{$barcode}->[2]++;
				$Offset = $i;
				last;
			}
		}
	}
	
	#Extract all construct features assuming all offsets are correct
	$promoter = substr( $sequence, 6 + $Offset,  24);
	$gRNA  = substr( $sequence, 30 + $Offset, 20 );
	$tracr = substr( $sequence, 50 + $Offset);

	#Check if the promoter is intact
	if($promoter eq 'CCCTATCAGTGATAGAGACTCGAG') {
		$CriteriaMatched++;
		$Results{$barcode}->[3]++;
	}

	#Make histogram of where tracrs are found, which will indicate amount of 20nt inserts
	#Only proceed with those reads where the tracr is in the correct position
	for(my $i=40;$i<=length($sequence);$i++) {
		if(substr($sequence,$i,8) eq 'GTTTTAGA') {
			$Histo{$i-50-$Offset}++;
			if($i==50+$Offset) {
				$CriteriaMatched++;
				$Results{$barcode}->[4]++;
			}
		}	
	}

	#If all criteria are met, count this read as a correct read
	if ( $CriteriaMatched == 4 ) {
		$CorrectReads++;
		$Results{$barcode}->[5]++;
		print OUTPUT $barcode . $promoter . $gRNA . $tracr . "\n";
	}
}

#Output the tracrRNA positional histogram to the report file
print REPORT "tracrRNAs found relative to expected:\n";
foreach $HistoDistance (sort (keys %Histo)) {
	print REPORT "Distance\t" . ($HistoDistance) . "\t" . $Histo{$HistoDistance} . "\n";
}
print REPORT "\n\n";


print REPORT "Barcode\tReads\tOf which by match\tPromoter seeds found\tCompletely Correct Promoters\ttracr found 20nt after promoter\tCompletely correct\n";


foreach $barcode ( keys %Results ) {
	if ( grep( /$barcode/, @Barcodes ) ) {
		print REPORT "$barcode\t";
		for ( $counter = 0 ; $counter <= 5 ; $counter++ ) {
			print REPORT sprintf( "%i", $Results{$barcode}->[$counter] ) . "\t";
			$Totals[$counter] += $Results{$barcode}->[$counter];
		}
		if ( $Results{$barcode}->[0] > 0 ) {
			print REPORT sprintf( "%4.2f%%", 100 * ( $Results{$barcode}->[5] / $Results{$barcode}->[0] ) ) . "\n";
		}
		else {
			print REPORT sprintf( "%4.2f%%", 0 ) . "\n";
		}
	}
}
print REPORT sprintf( "TOTAL\t%i\t%i\t%i\t%i\t%i\t%i", $Totals[0], $Totals[1], $Totals[2], $Totals[3], $Totals[4], $Totals[5]);

print REPORT sprintf(
	"\n\t\t%4.2f%%\t%4.2f%%\t%4.2f%%\t%4.2f%%\t%4.2f%%",
	100 * $Totals[1] / $Totals[0],
	100 * $Totals[2] / $Totals[0],
	100 * $Totals[3] / $Totals[0],
	100 * $Totals[4] / $Totals[0],
	100 * $Totals[5] / $Totals[0],
);
print REPORT "\n\nAnalyzed reads\t" . sprintf( "%i", $RecordsAnalyzed );
print REPORT "\nCorrect reads\t" . sprintf( "%i", $CorrectReads ) . "\t" . sprintf( "%4.2f", 100 * $CorrectReads / $RecordsAnalyzed ) . "%\n";
close(INPUT)  or die "Could not close input file $InputFile.\n";
close(OUTPUT) or die "Could not close output file $OutputFile.\n";
close(REPORT) or die "Could not close report file $ReportFile.\n";

sub MatchBarcode($@) {
	my ( $Barcode, @BarcodeList ) = @_;
	my $MatchesFound = 0;
	my $MatchedBarcode;
	foreach my $BarcodeFromList (@BarcodeList) {
		if ( ScoreTwoStrings( $Barcode, $BarcodeFromList ) <= 1 ) {
			$MatchedBarcode = $BarcodeFromList;
			$MatchesFound++;
		}
	}
	if ( $MatchesFound == 1 ) {
		return $MatchedBarcode;
	}
	else {
		return 0;
	}
}

sub ScoreTwoStrings($$) {
	my ( $Barcode, $BarcodeFromList ) = @_;
	my $Deviations = 0;
	for ( my $i = 0 ; $i < ( length $Barcode ) ; $i++ ) {
		if ( ( substr $Barcode, $i, 1 ) ne ( substr $BarcodeFromList, $i, 1 ) ) {
			$Deviations++;
		}
	}
	return $Deviations;
}
