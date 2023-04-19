#!perl -w
use strict;
use utf8;
use open qw(:std :utf8);

sub CleanList($){
	my($str) = @_;
	return $str if(! ($str =~ s/^\{([^\{\}]*)\}$/$1/is));
	my(@strs) = split(/\n/, $str);
	my($tmp, %labels);
	$str ="";
	foreach $tmp (@strs) {
		if($tmp =~ /^\s*([a-z0-9_]{4}\:)(.*)$/is) {
			my($key, $value) = ($1, $2);
			if(! exists($labels{$key})) {
				$labels{$key} = $value;
				$str .= $tmp . "\n";	
			} else {
#				print("Deleted: $tmp\n");
				$str .= "// // " . $tmp . "\n";	
			}
		} else {
			$str .= $tmp . "\n";	
		}
	}
	return "\{$str\}";
}

sub ChangeFile($) {
	my($fname) = @_;
	print("Parsing $fname\n");
	open(FROMFILE, "<:encoding(UTF-8)", $fname) || die "Can't open: ".$fname;
	my($res, $buff, $str, $state, $line) = ("", "", "", 0, 0);
	while(<FROMFILE>) {
		print("\r$line ");
		$line ++;
		$str .= $_;
		while($_ ne "") {
# not inside buffer
			if($state == 0) {
				if(s/^(.*?)\{//s) {
					$res .= $1;
					$state = 1;
					$buff = "{";
				} else {
					$res .= $_;
					$_ = "";
				}
			} else {
# gathering buffer
				if(s/^([^\{]*?\})//s) {
					$buff .= $1;
					$res .= CleanList($buff);
					$buff = "";
					$state = 0;	
				} elsif(s/^([^\}]*?)\{//s) {
# restart buffer
					$res .= $buff . $1;
					$buff = "{";
				} else {
					$buff .= $_;
					$_ = "";
				}
			}
		}
	}
	close(FROMFILE);
	$res .= $buff;
	print("\r");
# do not rewrite unchaged file
	if($str ne $res) { 
		open(TOFILE, ">:encoding(UTF-8)", "temp.tmp") || die("Can't create: temp.tmp");
		print TOFILE $res;
		close(TOFILE);
		if (unlink($fname)) {
			if (rename ("temp.tmp", $fname)) { 
				print("Result saved to $fname\n");
			} else { 
				print("temp.tmp can\'t be renamed. Result saved to temp.tmp\n");
			}
		} else {
			print("$fname can\'t be deleted. result saved to temp.tmp. ");
		}
	}
}

sub main()
{
	print("Remove duplicate cargoes from cargo lists in switches\nVersion 0.1\n");
	my($name) = ($ARGV[0]);
	$name = "" if(not defined($name));
	if(($name eq "") || (not(-e $name)) || (-d $name)) {                            
		die("Can't find $name\n");
	}
        ChangeFile($name);
}

main()
#end
