$NumberOfCores=32;
my $RefSeqFile = "/media/Bastiaan_Portable/Work/Active Projects/iKRUNCH/software/RefSeq/refGene.txt";
open (IN, $RefSeqFile) or die;
$CurrentCore=0;
if [ ! -d parallelscripts ]
then
	mkdir parallelscripts
fi
for (my $i=0;$i<$NumberOfCores;$i++) {
	$OutputFileHandle = 'OUT.' . $i;
	$OutputFile = 'parallelscripts/CRISPRSearchChunk.' . $i;
	open ($OutputFileHandle, ">", $OutputFile) or die "ERROR: Cannot open outputfile $OutputFile\n";
}

while (defined(my $Line = <IN>)) {
	chomp($Line);
	my @RefSeqValues = split( /\t/, $Line );
	$RefSeqID = $RefSeqValues[1];
	unless (-e '/home/NKI/b.evers/output/$RefSeqID.qualities.4') {
		$CurrentCore = 0 if ($CurrentCore==$NumberOfCores);
		$OutputFileHandle = 'OUT.' . $CurrentCore;
		select $OutputFileHandle;
		print "./RunRefSeq.sh $RefSeqID\n";
		$CurrentCore++;
	}
}
close (IN) or die "ERROR: Cannot close inputfile";
for (my $i=0;$i<$NumberOfCores;$i++) {
	$OutputFileHandle = 'OUT.' . $i;
	$OutputFile = 'scripts/CRISPRSearchChunk.' . $CurrentCore;
	close ($OutputFileHandle) or die "ERROR: Cannot close outputfile $OutputFile\n";
}
