use Getopt::Std;
use warnings;
use strict;
require 'FetchGenomicSequence.pl';

sub FetchGenomicSequence($$$);
my $ScriptName="ObtainValidProtospacersFromGenomicPosition.pl";
my %opts;
my %TargetSites;

getopt( 'ocse', \%opts );
print "Usage: perl $ScriptName -o OutputFile -c Chromosome -s StartPosition -e EndPosition\n";
die "ERROR in $ScriptName: No Outputfile given.\n" unless my $OutputFile = $opts{'o'};
die "ERROR in $ScriptName: No query chromosome given.\n" unless my $QueryChromosome = $opts{'c'};
die "ERROR in $ScriptName: No query startsite given.\n" unless my $QueryStart = $opts{'s'};
die "ERROR in $ScriptName: No query endsite given.\n" unless my $QueryEnd = $opts{'e'};
open (OUT, ">", $OutputFile) or die "Cannot open outpufile $OutputFile\n";


my $QuerySequenceFW = FetchGenomicSequence($QueryChromosome, $QueryStart-18, $QueryEnd);
my $QuerySequenceRV = FetchGenomicSequence($QueryChromosome, $QueryStart, $QueryEnd+18);
my $Pos;
my $Neg;

#Search for valid protospacers in the sense strand
#while ( $ExonSequenceFW =~ /(?<=(.{21}(G|A)))(G)/g ) { //UNCOMMENT THIS LINE FOR INCLUDING NAG PAMs AS VALID PROTOSPACERS
while ( $QuerySequenceFW =~ /(?<=(.{21}(G)))(G)/g ) {
	$TargetSites{substr( $1, 0, 20 )}++;
	$Pos++;
}
	
#Search for valid protospacers in the antisense strand
#while ( $ExonSequenceRV =~ /(?=(.(C|T).{21}))(C)/g ) { //UNCOMMENT THIS LINE FOR INCLUDING NAG PAMs AS VALID PROTOSPACERS
while ( $QuerySequenceRV =~ /(?=(.(C).{21}))(C)/g ) {
	my $TargetSequence = substr($1,3,20);
	$TargetSequence =~ tr/ACTG/TGAC/;
	$TargetSequence = reverse($TargetSequence);
	$TargetSites{$TargetSequence}++;
	$Neg++;
}

	
foreach my $TargetSite ( keys %TargetSites ) {
	#Test for >5xT in the sequence
	unless ($TargetSite =~ /TTTTT/) {
		print OUT "$TargetSite" . "CGG\n";
		print OUT "$TargetSite" . "TGG\n";
		print OUT "$TargetSite" . "AGG\n";
		print OUT "$TargetSite" . "GGG\n";
		#print OUT "$TargetSite" . "CAG\n";
		#print OUT "$TargetSite" . "TAG\n";
		#print OUT "$TargetSite" . "AAG\n";
		#print OUT "$TargetSite" . "GAG\n";
	}
}

print "$Pos Positive and $Neg Negative target sites found.\n";
close (OUT) or die "ERROR in $ScriptName: Cannot close outputfile $OutputFile\n";
