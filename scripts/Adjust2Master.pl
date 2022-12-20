#!/usr/bin/perl -w
use strict;

# MVP: This script should add commented cargo labels to capacity file to be shure, that a list in capacity file is up to date with cargo table 
# TODO future version should work with loading and unloading speed
# TODO more future version should be used for translation - use eng file as template for other files
# NB: should also support case, when destination file hase some data, not represented in the master file

use utf8;
use open qw(:std :utf8);
#use feature "unicode_strings";
#no bytes;

# Required data:
# Header separaton - parts before the separator are ignored for both the files. If ommited, the beginning of the file is parsed as a first group, 
# but the separator is always placed into ditination file, even if it was not represented
# group separator expreassion (may be a multyline expression)
# master file template (key-value)
# destination file template (key value) 
# NB: in cargo table fomat is "LABL,", while in capacity file the format is "LABL:"
# Footer separator - parts after the separator are ignored for both the files. If ommited, the ending of the file ends the last group, 
# but the separator is always placed into ditination file, even if it was not represented

sub main()
{
	print("Adjust file acording master file\nParameters - master file, file to change, rules");
}

main()
#end
