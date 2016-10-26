#!/usr/local/bin/perl
# Mike McQuade
# Local-alignment.pl
# Finds the highest scoring local alignment of
# the strings presented.

# Define the packages to use
use strict;
use warnings;
use List::Util qw(max);
use List::MoreUtils qw(firstidx);

# Initialize variables
my ($indelPenalty,$firstString,$secondString,$runningMax,@maxLocation,@grid,@pam250);

# Define the variables for indel penalty, pam250, running max and max location
$indelPenalty = -5;
$runningMax = 0;
@maxLocation = (0,0);

@pam250 = (
	[2,-2,0,0,-3,1,-1,-1,-1,-2,-1,0,1,0,-2,1,1,0,-6,-3],
	[-2,12,-5,-5,-4,-3,-3,-2,-5,-6,-5,-4,-3,-5,-4,0,-2,-2,-8,0],
	[0,-5,4,3,-6,1,1,-2,0,-4,-3,2,-1,2,-1,0,0,-2,-7,-4],
	[0,-5,3,4,-5,0,1,-2,0,-3,-2,1,-1,2,-1,0,0,-2,-7,-4],
	[-3,-4,-6,-5,9,-5,-2,1,-5,2,0,-3,-5,-5,-4,-3,-3,-1,0,7],
	[1,-3,1,0,-5,5,-2,-3,-2,-4,-3,0,0,-1,-3,1,0,-1,-7,-5],
	[-1,-3,1,1,-2,-2,6,-2,0,-2,-2,2,0,3,2,-1,-1,-2,-3,0],
	[-1,-2,-2,-2,1,-3,-2,5,-2,2,2,-2,-2,-2,-2,-1,0,4,-5,-1],
	[-1,-5,0,0,-5,-2,0,-2,5,-3,0,1,-1,1,3,0,0,-2,-3,-4],
	[-2,-6,-4,-3,2,-4,-2,2,-3,6,4,-3,-3,-2,-3,-3,-2,2,-2,-1],
	[-1,-5,-3,-2,0,-3,-2,2,0,4,6,-2,-2,-1,0,-2,-1,2,-4,-2],
	[0,-4,2,1,-3,0,2,-2,1,-3,-2,2,0,1,0,1,0,-2,-4,-2],
	[1,-3,-1,-1,-5,0,0,-2,-1,-3,-2,0,6,0,0,1,0,-1,-6,-5],
	[0,-5,2,2,-5,-1,3,-2,1,-2,-1,1,0,4,1,-1,-1,-2,-5,-4],
	[-2,-4,-1,-1,-4,-3,2,-2,3,-3,0,0,0,1,6,0,-1,-2,2,-4],
	[1,0,0,0,-3,1,-1,-1,0,-3,-2,1,1,-1,0,2,1,-1,-2,-3],
	[1,-2,0,0,-3,0,-1,0,0,-2,-1,0,0,-1,-1,1,3,0,-5,-3],
	[0,-2,-2,-2,-1,-1,-2,4,-2,2,2,-2,-1,-2,-2,-1,0,4,-6,-2],
	[-6,-8,-7,-7,0,-7,-3,-5,-3,-2,-4,-4,-6,-5,2,-2,-5,-6,17,0],
	[-3,0,-4,-4,7,-5,0,-1,-4,-1,-2,-2,-5,-4,-4,-3,-3,-2,0,10]
);

# Open the file to read
open(my $fh,"<ba5f.txt") or die $!;

# Read in the values from the file
$firstString = <$fh>;
chomp($firstString);
$secondString = <$fh>;
chomp($secondString);

# Populate the first row of the grid with as many zeros
# as the length of the first string.
my @tempArr = (0);
for (my $i = 0; $i <= length($firstString); $i++) {
	push @tempArr,0;
}
push @grid,[@tempArr];

# Populate the first column of the grid with as many zeros
# as the length of the second string.
for (my $i = 1; $i <= length($secondString); $i++) {
	push @grid,[0];
}

# Calculate the rest of the grid
for (my $i = 1; $i <= length($firstString); $i++) {
	for (my $j = 1; $j <= length($secondString); $j++) {
		my $firstChar = substr($firstString,$i-1,1);
		my $secondChar = substr($secondString,$j-1,1);
		$grid[$i][$j] = max(
								0,
								$grid[$i-1][$j] + $indelPenalty,
								$grid[$i][$j-1] + $indelPenalty,
								$grid[$i-1][$j-1] + matchVal($firstChar,$secondChar)
							);

		# Keep a note of where the highest value is in the grid
		if ($grid[$i][$j] > $runningMax) {
			@maxLocation = ($i,$j);
			$runningMax = $grid[$i][$j];
		}
	}
}

# Call the output function with the lengths of the
# given strings.
outputLocalAlign();

# Close the file
close($fh) || die "Couldn't close file properly";



# Returns the penalty for a specific match of characters
sub matchVal {
	my $firstChar = $_[0];
	my $secondChar = $_[1];
	
	my @index = ('A','C','D','E','F','G','H','I','K','L','M','N','P','Q','R','S','T','V','W','Y');
	my $firstIndex = firstidx { $_ eq $firstChar } @index;
	my $secondIndex = firstidx { $_ eq $secondChar } @index;

	return $pam250[$firstIndex][$secondIndex];
}

# Print out the alignment of the two given strings
sub outputLocalAlign {
	# Define local variables
	my $alignmentA = "";
	my $alignmentB = "";
	# Begin the backtrack at the location of the maximum value
	my $i = $maxLocation[0];
	my $j = $maxLocation[1];

	# Backtrack the path defined by the grid
	while ($i > 0 || $j > 0) {
		# If the given square is equal to zero, the loop ends immediately
		if ($grid[$i][$j] == 0) {last}
		# If there is a match or mismatch, concatenate the last letter of each string
		# with its respective alignment.
		if ($i > 0 && $j > 0 && $grid[$i][$j] == $grid[$i-1][$j-1] + matchVal(substr($firstString,$i-1,1),substr($secondString,$j-1,1))) {
			$alignmentA = substr($firstString,$i-1,1).$alignmentA;
			$alignmentB = substr($secondString,$j-1,1).$alignmentB;
			$i--;
			$j--;
		# If there is a gap, one alignment string receives the last letter
		# of one of the strings while the other receives a dash.
		} elsif ($i > 0 && ($grid[$i][$j] == $grid[$i-1][$j] + $indelPenalty)) {
			$alignmentA = substr($firstString,$i-1,1).$alignmentA;
		    $alignmentB = "-".$alignmentB;
		    $i--;
		} else {
			$alignmentA = "-".$alignmentA;
		    $alignmentB = substr($secondString,$j-1,1).$alignmentB;
		    $j--;
		}
	}
	# Output the score and the alignments for the two strings
	print $runningMax."\n";
	print $alignmentA."\n";
	print $alignmentB."\n";
}