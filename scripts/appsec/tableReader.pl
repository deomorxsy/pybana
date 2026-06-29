#!/bin/perl -w

# convert a xlxs file to csv

# headers
use v5.38;
use strict;
use warnings;

# pragmas
use feature qw/ state /;

local $SIG{__DIE__} = sub {warn @_; exit 1};

# libraries
use Spreadsheet::XLSX;

# test
#my $filename = $ARGV[0];
#my $coord = $ARGV[1];

my $filename = shift or die "Usage: $0 file.xlsx\n";

#$rotate = 1 if( defined $ARGV[2] && $ARGV[2] eq "-rotate");

# if coordinates weren't given
if( !$coords ) {
    usage( "No co-ordinates defined") ;
    exit ;
}

# if the filename is not valid
if (! -f $filename) {
    usage( "file $filename does not exist");
}

my $sheet = xlsxmm -> new();

sub reader() {
    return (
        hmm
    )
}
