#!perl
# -w
use strict;

my(%nameallstrings) = ();
my(%nameallids) = ();
my($cross, $name) = (0, "");

sub msort($)
{
	my($str) = @_;
	return "" if ($str eq "");
	$str=~s/\s+$//;
	my(@list) = split(/\n/, $str);
	@list = (sort {uc($a) cmp uc($b)} @list);
	return join("\n", @list)."\n";
}

sub ldirectory($)
{
	my($dir, @dirs, $i, $t) = @_;
	if (opendir (DIR,$dir)) {
		@dirs=grep {/\.lng$/i and (!(-d "$dir/$_"))} readdir DIR;
		closedir DIR;
	}
	foreach $t (@dirs) {
	        my($buff1, $buff2, $buff3) = ("", "", "");
		open(FFILE,"<$dir/$t") || die "Can\'t read from $t\n";
		while (<FFILE>) {
			s/\s*$/\r\n/;
			while(s/UNUSED_STR/STR/) {
			};
			if (/(STR_[_a-z0-9]*)/i) {
				if (exists($nameallstrings{$1})) {
					$buff1.=$_;
					$nameallstrings{$1}{$dir."/".$t}=1;
				} else {
					$buff2.="UNUSED_".$_;
				}
			} else {
				$buff3 .= msort($buff1) . msort($buff2) . $_;
				$buff1 = ""; $buff2 = "";
			}
		}
		$buff3 .= msort($buff1) . msort($buff2);
		close(FFILE);
		open(FFILE,">$dir/$t") || die "Can\'t write to $t\n";
		print FFILE $buff3;
		close(FFILE);
	}
}

sub wdirectory($)
{
	my($dir,@dirs,$i,$t,$buff, $tt)=@_;
	$tt = $dir;
	$tt =~ s/^$name//;      	
	if (opendir (DIR,$dir)) {
		@dirs=grep {!/^\.+$/ and (-d "$dir/$_")} readdir DIR;
		closedir DIR;
	}
	foreach $t (@dirs) {
		wdirectory($dir.'/'.$t)
	}
	if (opendir (DIR,$dir)) {
		@dirs=grep {/\.pnml$/i and (!(-d "$dir/$_"))} readdir DIR;
		closedir DIR;
	}
	foreach $t (@dirs) {
		open(FFILE,"<$dir/$t") || die "Can\'t read from $t\n";
		$buff=join('',<FFILE>);
		close(FFILE);
		
		while($buff=~/item\s*\(FEAT_TRAINS,\s*([_a-z0-9]+),\s*([0-9]+)\)/ig) {
			if (exists $nameallids{$2}) {
				$nameallids{$2} .= ", $1 ($tt/$t)";
				$cross = $2;
			} else {
				$nameallids{$2} = "$1 ($tt/$t)";
			}
		} 	

		while($buff =~ /((?:TTD_|)STR_[_a-z0-9]*)/ig) {
			$nameallstrings{$1}{$dir."/".$t}=1 if (!($1=~/^TTD_/));
		}
	}
}

sub main() {
	my($t1, $t2, $t3, $t4, $t5);
	use Cwd;
	$name=(cwd());
	$name=~s#\\#\/#g;
	$name=~s#\/$##g;
	$name=~s#\/src$##g;
	$name=~s#\/lang$##g;
	if ((-e $name."/src") and (-d $name."/src")) {
		print "Starting in $name/src.\n";
		wdirectory($name."/src");
	} else {
		print($name."/src is unavailable.\n");
	}
	if ((-e $name."/lang") and (-d $name."/lang")) {
		print "Cleaning in $name/lang.\n";
		ldirectory($name."/lang");
	} else {
		print($name."/lang is unavailable.\n");
	}

	open(FFILE,">$name/src/IDs_usage") || die "Can\'t write to IDs_usage\n";
	$t5 = (sort {$b <=> $a} (keys(%nameallids)))[0];
	for ($t1 = 124; $t1 <= $t5 ; $t1++) {
		if (exists $nameallids{$t1}) {
		        print FFILE $t1." -> ".$nameallids{$t1} . "\n";	        	
		} else {
		        print FFILE $t1." ->\n";	        	
		}
	}
	close(FFILE);
	print "Max ID used: ".($t1-1)."\n";
	
	$t4="";
	unlink("$name/lang/_Missing.txt");
	foreach $t1 (sort {uc($a) cmp uc($b)} (keys(%nameallstrings))) {
	        $t3=0;
		foreach $t2 (sort {uc($a) cmp uc($b)} (keys(%{$nameallstrings{$t1}}))) {
		        $t3++ if ($t2=~/lng$/i);
	 	}
	        $t4.="$t1\n" if ($t3 == 0);	        	
	}
	if ($t4 ne "") {
		open(FFILE,">$name/lang/_Missing.txt") || die "Can\'t write to _Missing.txt\n";
	        print FFILE $t4;	        	
		close(FFILE);
		die("Missing strings found!\n");
	}
	if ($cross > 0) {
		die("IDs erros found ($cross)!\n");
	}
}

main();

# почему-то не выловил исчезновение строк после вмешательства Вована