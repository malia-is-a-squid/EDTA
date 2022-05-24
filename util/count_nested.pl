#!/usr/bin/env perl
use warnings;
use strict;
#Shujun Ou (oushujun@iastate.edu) 08/10/2019

my $usage = "\nCount all-versus-all misclassifications using the cleanup_nested.pl .stat file
	perl count_nested.pl -in sequence.fa.stat -cat [redun|nested|all] > sequence.fa.stat.sum\n";

my $input = ''; #input file .stat generated by cleanup_nested.pl
my $cat = "all"; #all: all input entries; redun: only redundant entries (Discarded types); nested: only nested entries (Cleaned types)

my $k=0;
foreach (@ARGV){
	$input = $ARGV[$k+1] if /^-in$/i and $ARGV[$k+1] !~ /^-/;
	$cat = lc $ARGV[$k+1] if /^-cat$/i and $ARGV[$k+1] !~ /^-/;
	$k++;
	}

die $usage unless $cat =~ /all|nested|redun/;
open IN, "<$input" or die $usage;
print "Confusion matrix of $input for the $cat category\n";

my %stat;
my %types;
while (<IN>){
	s/\.$//;
	next if (/Discarded/ and $cat eq "nested");
	next if (/Cleaned/ and $cat eq "redun");
	my ($type1, $type2) = ($1, $2) if /[\||#]([0-9a-z\/_]+)\s+.*[\||#]([0-9a-z\/_]+)(;|\s+)/i;
	next unless defined $type1 and defined $type2;
	$types{$type1}++;
	$types{$type2}++;
	$stat{"$type1-$type2"}++;
	}
close IN;

# remove single-event categories
while (my ($key, $value) = each (%types)) {
	delete $types{$key} if $value <= 1;
	}

my @types = sort {$a cmp $b} keys %types;
local $" = "\t";
print "\t@types\tMisclas_rate\n";
foreach my $type1 (@types){
	print "$type1\t";
	$stat{"$type1-$type1"} = 0 unless exists $stat{"$type1-$type1"};
	my $true = $stat{"$type1-$type1"};
	my $all = 0;
	foreach my $type2 (@types){
		$stat{"$type1-$type2"} = 0 unless exists $stat{"$type1-$type2"};
		$all += $stat{"$type1-$type2"};
		print $stat{"$type1-$type2"}."\t";
		}
	my $Misclas_rate = 0;
	$Misclas_rate = sprintf("%.4f", ($all-$true)/$all) if $all > 0;
	print "$Misclas_rate\n";
	}

