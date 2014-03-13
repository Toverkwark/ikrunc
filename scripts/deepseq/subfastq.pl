use Getopt::Long;

if ($#ARGV<1) {
        die "subfastq.pl -input -output -records -offset\n";
}


GetOptions (   "input=s"    		=> \$InputFile,
		"output=s"		=> \$OutputFile,
		"records=i"		=> \$Records,
		"offset=i" 		=> \$Offset,
);
if(!$OutputFile)
{
	$OutputFile=$InputFile . ".sub";
}
open (INPUT, $InputFile) or die "Input file $InputFile is not accessible.\n";
open (OUTPUT, ">", $OutputFile) or die "Output file $OutputFile is not accessible.\n";

for ($Record=1;$Record<=$Offset;$Record++)
{
	for ($RecordLine=1;$RecordLine<=4;$RecordLine++)
	{
		$line=<INPUT>;
	}
}

for ($Record=1;$Record<=$Records;$Record++)
{
	for ($RecordLine=1;$RecordLine<=4;$RecordLine++)
	{
		$line=<INPUT>;
		print OUTPUT $line;		
	}
}

close (INPUT) or die "Could not close input file $InputFile.\n";
close (OUTPUT) or die "Could not close output file $OutputFile.\n";
