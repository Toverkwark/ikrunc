#!/bin/bash
#This script takes as input a RefSeq ID. It then finds all possible protospacers in both reading frames for that RefSeq ID
#Next, it will take iterative steps to determine for every possible protospacer, how many relatives it has and add that as columns to the 
#qualities file. The extra columns in the final file represent:
#
#Column 19: Genome-wide occurences of protospacers with identical 12nt 3' target sequences INCLUDING the intended target
#Column 20: How many of those are near exons
#Column 21: Genome-wide occurences of 1MM relatives of target site
#Column 22: How many of those are near exons
#Column 23: Genome-wide occurences of 2MM relatives of target site
#Column 24: How many of those are near exons
#Column 25: Genome-wide occurences of 3MM relatives of target site
#Column 26: How many of those are near exons
#Column 27: Genome-wide occurences of 4MM relatives of target site
#Column 28: How many of those are near exons
#To save computational resources, the next column is only calculated if the previous is 0. This can be overridden by using the -l flag
#in the QualityScoreSites script. A -1 value in any column means the calculation has not been performed.

#Initialize locations
SCRIPTDIR=/home/NKI/b.evers/mm10/scripts
OUTPUTDIR=/home/NKI/b.evers/mm10/output
GENOMEINDEX=/home/NKI/b.evers/mm10/genome-index/mm10

#Only run this script if the end result does not yet exist
echo Processing $1
if [ ! -f $OUTPUTDIR/$1.qualities.4 ]; then

	#First, obtain all valid protospacers for this particular refseq
	echo 'Find all protospacers for' $1
	perl "$SCRIPTDIR/ObtainValidProtospacersFromRefSeq.pl" -r $1 -o $OUTPUTDIR/$1.protospacers

	#Then, find genome-wide occurances of identical target sites
	echo 'Find genome-wide occurances for identical target sites for' $1
	bowtie2 $GENOMEINDEX -r $OUTPUTDIR/$1.protospacers -t -S $OUTPUTDIR/$1.matched --no-hd --score-min L,-5,0 -k 2 --mm

	#Determine how many identical targets in the genome each protospacer has
	echo 'Filter protospacer list for unique ones for' $1
	perl "$SCRIPTDIR/IdentifyIdenticalTargetSites.pl" -i $OUTPUTDIR/$1.matched -o $OUTPUTDIR/$1.qualities

	#Filter out all good target sites 
	#First, find target sites that do not have equal 3' 12nt targets somewhere else
	echo 'Find protospacers with identical 3 primer 12nt targets for' $1
	perl "$SCRIPTDIR/QualityScoreSites.pl" -i $OUTPUTDIR/$1.qualities -o $OUTPUTDIR/$1.qualities.0 -d 0 -s 12 

	#Then, without filtering for that, continue by filtering out targets that have 1,2,3 or 4 MM Relatives
	echo 'Find 1MM relatives for' $1
	perl "$SCRIPTDIR/QualityScoreSites.pl" -i $OUTPUTDIR/$1.qualities.0 -o $OUTPUTDIR/$1.qualities.1 -d 1 -s 20 -l
	echo 'Find 2MM relatives for' $1
	perl "$SCRIPTDIR/QualityScoreSites.pl" -i $OUTPUTDIR/$1.qualities.1 -o $OUTPUTDIR/$1.qualities.2 -d 2 -s 20
	echo 'Find 3MM relatives for' $1
	perl "$SCRIPTDIR/QualityScoreSites.pl" -i $OUTPUTDIR/$1.qualities.2 -o $OUTPUTDIR/$1.qualities.3 -d 3 -s 20
	echo 'Find 4MM relatives for' $1
	perl "$SCRIPTDIR/QualityScoreSites.pl" -i $OUTPUTDIR/$1.qualities.3 -o $OUTPUTDIR/$1.qualities.4 -d 4 -s 20

	#Clean up intermediate files
	echo 'Clean up intermediate files for' $1
	rm $OUTPUTDIR/$1.protospacers
	rm $OUTPUTDIR/$1.matched
	rm $OUTPUTDIR/$1.qualities
	rm $OUTPUTDIR/$1.qualities.0
	rm $OUTPUTDIR/$1.qualities.1
	rm $OUTPUTDIR/$1.qualities.2
	rm $OUTPUTDIR/$1.qualities.3
fi
 
