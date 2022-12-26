#!/usr/bin/perl -w
use strict;

use utf8;
use open qw(:std :utf8);
#use feature "unicode_strings";
#no bytes;

# Required data:
# Header separaton - parts before the separator are ignored for both the files. TODO If ommited, the beginning of the file is parsed as a first group, 
# but the separator is always placed into ditination file, even if it was not represented
# group separator expression (may be a multyline expression)
# master file template (key-value)
# destination file template (key-value) 
# Footer separator - parts after the separator are ignored for both the files. If ommited, the ending of the file ends the last group, 
# TODO but the separator is always placed into ditination file, even if it was not represented
# TODO If data is represented in the wrong section, then it should be commented there and moved to the right section
# if data is represented several times, all the variants should be placed in the one place 

my($header_template, $footer_template, $section_template, $key_template, $key_separator_master, $key_separator_slave, $comment_format);

sub read_file($$) {
	my($fname, $separator) = (@_);
	my($header, $footer, @sections) = ("", "");
	my($count_sections, $count_keys) = (0, 0);
	print("Parsing $fname ...");
	open(FROMFILE, "<:encoding(UTF-8)", $fname) || die "Can't open: ".$fname;
	my($str) = join("", <FROMFILE>);
	close(FROMFILE);
	$str =~ s/\r//igs;
	$header = $1 if($str =~ s/^(.*?$header_template)//is);
	$footer = $1 if($str =~ s/($footer_template.*?)$//is);
# If there is no section in the file - die with error
	if(not $str =~ /^($section_template)(.*)$/is) { 
		die("No sections found in $fname\n");
	}
	while($str =~ s/^($section_template)(.*)$//is) {
		$count_sections++;
		my($section, $key_list) = ($1, $2);
                if($key_list =~ s/^(.*?)($section_template)(.*)$/$1/is) {
			$str = $2 . $3; 
		} 	
		my(%keys) = ();
		$key_list .= "\n";
# Ignore strings without a key  
# TODO decide, if there are multy-line values possible
		while($key_list =~ s/^(.*?)\n//is) {
			my($line) = ($1);
		        if($line =~ /^($key_template$separator)(.*)$/i) {
				my($key, $value) = ($1, $2);
				$count_keys++;  
				if(exists $keys{$key}) {
		        		@{$keys{$key}} = (@{$keys{$key}}, $value);	
				} else {
			        	@{$keys{$key}} = ($value);
				}			
			}
		}                
		my($tmp);
        	@{$keys{"-Section-Header-"}} = ($section);
		%{$tmp} = %keys;
		@sections = (@sections, $tmp);
	}
	print("success. Sections: $count_sections, keys: $count_keys\n");
	return ($header, $footer, @sections);
# returned structure:
# Array of header, footer, sections. Each section is a hash of keys - values, where value is an array of values (because 
# a file can contain several values per key). It is an error in general, but values should not be lost.
# a header (string) is a key in array # TODO refactor. Split header from keys (possible the header key may exist in the keys list)  
}

sub get_key_values($$$@) {
# this function collects the key values from all the sections
	my($search_key, $separator_master, $separator_slave, @sections) = (@_);
	$search_key =~ s/$separator_master$//igs;
	$search_key =~ s/^(\/\/|\#)//igs;
	$search_key =~ s/^\s*//igs;
	$search_key =~ s/\s*$//igs;
	my($section, $key, $key2, @results, %keys);
	my($has_comments, $result_key) = (0, "");
	@results = ();
	foreach $section (@sections) {
		%keys = %{$section};
		foreach $key (keys(%keys)) {
                        my($has_comments2) = (0);
	                $key2 = $key;
			$key2 =~ s/$separator_slave$//igs;
			$has_comments2 = 1 if ($key2 =~ s/^(\/\/|\#)//igs);
			$key2 =~ s/^\s*//igs;
			$key2 =~ s/\s*$//igs;
			if($key2 eq $search_key) {
		        	@results = (@results, @{$keys{$key}});
				$result_key = $key;
		        	$has_comments = 1 if ($has_comments2 == 1);
			}
		}			
	}
	return ($has_comments, $result_key, @results);
}

sub parse_files($$) {
	my($from_file, $to_file) = (@_);
	my($header_master, $footer_master, @sections_master) = (read_file($from_file, $key_separator_master));
	my($header_slave, $footer_slave, @sections_slave) = (read_file($to_file, $key_separator_slave));
# TODO because sections of the slave file are not used, transform slave sections into a single hash and use it, should be much faster
	my($sec_number, $result, $section, %keys, $key, @values) = (1, "");
	$result .= $header_slave;
	foreach $section (@sections_master) {
		%keys = %{$section};
	        $result .= join("", @{$keys{"-Section-Header-"}});
		print("Section: $sec_number\n");
		$sec_number++;
		foreach $key (sort {$a cmp $b} keys(%keys)) {
			if($key ne "-Section-Header-") {
				@values = get_key_values($key, $key_separator_master, $key_separator_slave, @sections_slave);
				if(scalar(@values) == 2) {
					$result .= "$comment_format $key" . join("\n$comment_format $key", @{$keys{$key}}) . "\n";
				} elsif(scalar(@values) == 3) {
					$result .= $values[1] . $values[2] . "\n";
				} else {
				        splice(@values, 0, 2);
					$result .= "$comment_format ERROR!!! Key has too many values\n";
					$result .= "$comment_format $key" . join("\n$comment_format $key", @values) . "\n";
				}
			}
# TODO check, if slave does not have unique values in the section. currently they are moved to the end of file 		
# TODO place them just after the nearest apropriate key in the same section, because it may be, for example, genders
		}
	}
# look for slave-only values and add them
	print("unused strings\n");
	$sec_number = 1;
	foreach $section (@sections_slave) {
		print("Section: $sec_number\n");
		$sec_number++;
		%keys = %{$section};
		foreach $key (sort {$a cmp $b} keys(%keys)) {
			if($key ne "-Section-Header-") {
				@values = get_key_values($key, $key_separator_slave, $key_separator_master, @sections_master);
				if(scalar(@values) == 2) {
					$result .= "$comment_format Value is not represented in the master file\n";
					$result .= "$key" . join("\n$key", @{$keys{$key}}) . "\n";
				} 
			}
		}
	}
	$result .= $footer_slave;
	print("\n");
#	$result =~ s/\n/\r\n/g;
# TODO not to rewrite file if it has not been changed
	open(TOFILE, ">:encoding(UTF-8)", "temp.tmp") || die("Can't create: temp.tmp");
	print TOFILE $result;
	close(TOFILE);
	if (unlink($to_file)) {
		if (rename ("temp.tmp", $to_file)) { 
			print("Result saved to $to_file\n");
		} else { 
			print("temp.tmp can\'t be renamed. Result saved to temp.tmp\n");
		}
	} else {
		print("$to_file can\'t be deleted. result saved to temp.tmp. ");
	}
}

sub main() {
	print("Adjust file acording master file. v0.1\nParameters - master file, file to change, rules\n");
	my($name_master, $name_slave, $rules) = ($ARGV[0], $ARGV[1], $ARGV[2]);
	$name_master = "" if(not defined($name_master));
	if(($name_master eq "") || (not(-e $name_master)) || (-d $name_master)) {                            
		die("Can't find $name_master\n");
	}
	$name_slave = "" if(not defined($name_slave));
	if(($name_slave eq "") || (not(-e $name_slave)) || (-d $name_slave)) {
		die("Can't find $name_slave\n");
	}
	if(uc($name_slave) eq uc($name_master)) {
		die("$name_slave and $name_master can't be the same\n");
	}
	if(not defined($rules)) {
		die("Rules not specifiled\n");	
	};
	if($rules =~ /^lng$/i) {
		print("Use language files rules\n");
		($header_template, $footer_template, $section_template, $key_template, $key_separator_master, $key_separator_slave, $comment_format) = 
		("\# begin main block.*?\n", "\# end main block", "\#\n\#.*?\n\#\n", "\#\{0\,1\}\\s\*\[a\-z\_0\-9\.\]\+\?\\s\*", "\:", "\:", "\#");
	} elsif($rules =~ /^ct2cl$/i) {
		print("Use CargoTable 2 Cargo list rules\n");
		($header_template, $footer_template, $section_template, $key_template, $key_separator_master, $key_separator_slave, $comment_format) = 
		("\/\/ begin main block.*?\n", "\/\/ end main block", "\/\/\\s\+\-\-\-.*?\n", "\[\/\]\{0\,2\}\\s\*\[a\-z\_0\-9\]\+\?\\s\*", "\,", "\:", "\/\/");
	} else {
		die("Rules \"$rules\" are unknown\n");	
	}
	parse_files($name_master, $name_slave);
}

main()
#end
                                                                        	