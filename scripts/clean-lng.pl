#!perl
# -w
use strict;

# todo
# находить неиспользуемые png и pnml файлы

my(%nameallstrings) = ();
my(%nameallids) = ();
my(%nameallpngs) = ();
my(%nameallpnmls) = ();
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
	my($dir, @dirs, $i, $t, $buff, $tt, $tt2)=@_;
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
		@dirs=grep {/\.png$/i and (!(-d "$dir/$_"))} readdir DIR;
		closedir DIR;
	}
	foreach $t (@dirs) {
		if(not exists $nameallpngs{"$tt/$t"}) {
			$nameallpngs{"$tt/$t"} = "";
		} 
	}
	if (opendir (DIR,$dir)) {
		@dirs=grep {/\.pnml$/i and (!(-d "$dir/$_"))} readdir DIR;
		closedir DIR;
	}

	foreach $t (@dirs) {
		open(FFILE,"<$dir/$t") || die "Can\'t read from $t\n";
		if(not exists $nameallpnmls{"$tt/$t"}) {
			$nameallpnmls{"$tt/$t"} = "";
		} 

		$buff=join('',<FFILE>);
		close(FFILE);
# Добавление записи об использовании pnml
		while($buff=~/\#include\s*\"([\\\/\.\_\-a-z0-9]+?)\"/isg) {
			# Добавить префикс пути, так как внутри пути относительные
			$tt2 = "$tt/$1";	
			# исправить ссылки вида src/addon/../align/align.pnml
			while($tt2 =~ s/([\.\_\-a-z0-9]+?)\/\.\.\///igs) {};
			if (exists $nameallpnmls{$tt2} and $nameallpnmls{$tt2} ne "") {
				$nameallpnmls{$tt2} .= ", ($tt/$t)";
			} else {
				$nameallpnmls{$tt2} = "($tt/$t)";
			}
		} 	
# Добавление записи об использовании png
		while($buff=~/\#define\s*IMAGEFILE[0-9]*\s*\"([\\\/\.\_\-a-z0-9]+?)\"/isg) {
			$tt2 = $1;	
			if (exists $nameallpngs{$tt2} and $nameallpngs{$tt2} ne "") {
				$nameallpngs{$tt2} .= ", ($tt/$t)";
			} else {
				$nameallpngs{$tt2} = "($tt/$t)";
			}
		} 	
		while($buff=~/spriteset\s*\([a-z0-9\_]+\s*\,\s*\"([\\\/\.\_\-a-z0-9]+?)\"\)/isg) {
			$tt2 = $1;	
			if (exists $nameallpngs{$tt2} and $nameallpngs{$tt2} ne "") {
				$nameallpngs{$tt2} .= ", ($tt/$t)";
			} else {
				$nameallpngs{$tt2} = "($tt/$t)";
			}
		} 	
# Добавление записи об использовании ID		
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
	my($t1, $t2, $t3, $t4, $t5, $count);
	use Cwd;
	$name=(cwd());
	$name=~s#\\#\/#g;
	$name.="\/" if (not $name=~/\/$/);
	$name=~s#\/src(\/)*$#\/#g;
	$name=~s#\/lang(\/)*$#\/#g;
	if ((-e $name."src") and (-d $name."src")) {
		print "Starting in ".$name."src.\n";
		wdirectory($name."src");
	} else {
		print($name."src is unavailable.\n");
	}
	if ((-e $name."lang") and (-d $name."lang")) {
		print "Cleaning in ".$name."lang.\n";
		ldirectory($name."lang");
	} else {
		print($name."lang is unavailable.\n");
	}

	open(FFILE,">".$name."src/IDs_usage") || die "Can\'t write to IDs_usage\n";
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
	
	$count = 0;
	open(FFILE,">".$name."src/PNGs_usage") || die "Can\'t write to PNGs_usage\n";
	foreach $t5 (sort {uc($a) cmp uc($b)} (keys(%nameallpngs))) {
	        print FFILE $t5 . " -> " . $nameallpngs{$t5} . "\n";
	        if ($nameallpngs{$t5} eq "") {
	        	print "$t5 is not used\n";
	        	$count ++;
	        }
	}
	close(FFILE);

	print("\n") if($count > 0);
	
	open(FFILE,">".$name."src/PNMLs_usage") || die "Can\'t write to PNMLs_usage\n";
	foreach $t5 (sort {uc($a) cmp uc($b)} (keys(%nameallpnmls))) {
	        print FFILE $t5 . " -> " . $nameallpnmls{$t5} . "\n";
	        print "$t5 is not used\n" if ($nameallpnmls{$t5} eq "");
	}
	close(FFILE);
	
	$t4="";
	unlink($name."lang/_Missing.txt");
	foreach $t1 (sort {uc($a) cmp uc($b)} (keys(%nameallstrings))) {
	        $t3=0;
		foreach $t2 (sort {uc($a) cmp uc($b)} (keys(%{$nameallstrings{$t1}}))) {
		        $t3++ if ($t2=~/lng$/i);
	 	}
	        $t4.="$t1\n" if ($t3 == 0);	        	
	}
	if ($t4 ne "") {
		open(FFILE,">".$name."lang/_Missing.txt") || die "Can\'t write to _Missing.txt\n";
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