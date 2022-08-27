#!/usr/bin/perl -w
use strict;

# use POSIX;

use utf8;
use open qw(:std :utf8);

my($last_str_length) = (0);
sub WPrint($) {
	my($str) = @_;
	for(my($i)=0; $i <= $last_str_length; $i++) {
		print(" ");
	}
#	sprintf("% ".$last_str_length."\r");
	print("\r$str\r");
	$last_str_length = length($str);
}

sub FixBlockRight($$) { 
# Эта функция выравнивает блок по левому краю
	my($s_buff, $spliter) = @_;
	$s_buff =~ s/^\n+//;
	$s_buff =~ s/\n+$//;
	my(@block) = split(/\n/, $s_buff);
	my($calc, $s_temp, $s_temp2, $len)=(0, "", "");
	foreach $s_temp (@block) {
		$len = length ($s_temp);
		$calc = $len if ($len > $calc);				
	}
	foreach $s_temp (@block) {
	        $len = $calc - length ($s_temp) + 1;
		$s_temp2 .= $s_temp . sprintf("%-${len}s", " "). "  $spliter\n";					
	}
	return $s_temp2;
}

sub FixBlockMiddle($$) {
# Эта функция выравнивает блок по разделителю
	my($s_buff, $spliter) = @_;
	$s_buff =~ s/^\n+//;
	$s_buff =~ s/\n+$//;
	my(@block) = split(/\n/, $s_buff);
	my($calc, $s_temp, $s_temp2, $s_temp3, $len)=(0, "", "");
	foreach $s_temp (@block) {
		$s_temp3 = $s_temp;
	        $s_temp3 =~ s/\s*$spliter.*$//;
		$len = length ($s_temp3);
		$calc = $len if ($len > $calc);				
	}
	return $s_buff."\n" if ($calc == 0);
	foreach $s_temp (@block) {
       	        $s_temp =~ s/\s*$spliter(.*)$//;
       	        $s_temp3 = $1;
	        if ($s_temp eq "") {
	        	$len = 0;
	        } else {
	        	$len = $calc - length ($s_temp) + 1;
	        }
		$s_temp2 .= $s_temp . sprintf("%-${len}s", " "). "$spliter$s_temp3\n";					
	}
	return $s_temp2;
}

sub FixBlockLeft($$) {
# Эта функция выравнивает блок по разделителю слева
	my($s_buff, $spliter) = @_;
	$s_buff =~ s/^\n+//;
	$s_buff =~ s/\n+$//;
	my(@block) = split(/\n/, $s_buff);
	my($calc, $s_temp, $s_temp2, $s_temp3, $len)=(0, "", "");
	foreach $s_temp (@block) {
		$s_temp3 = $s_temp;
	        $s_temp3 =~ s/$spliter.*$//;
		$len = length ($s_temp3);
		$calc = $len if ($len > $calc);				
	}
	return $s_buff."\n" if ($calc == 0);
	foreach $s_temp (@block) {
       	        $s_temp =~ s/^\s*(.*?)\s*$spliter\s*//;
       	        $s_temp3 = $1;
	        if ($s_temp eq "") {
	        	$len = 0;
	        } else {
	        	$len = $calc - length ($s_temp3);
	        }
		$s_temp2 .= sprintf("%-${len}s", " "). "$s_temp3$spliter $s_temp\n";					
	}
	return $s_temp2;
}

sub ChangeFile($) {
	my($name) = @_;
	my($bak, $s, $s_old);
	my(@strs);
	my($s_buff, $s_total, $str);

	open(FROMFILE, "<".$name) || return "Can't open: ".$name;
	binmode(FROMFILE);

	$s = join("", <FROMFILE>);
	$s_old = $s;

	WPrint("Changing $name");

# Заменить все табы на пробелы
        $s =~ s/\t/        /g;
# не использовать \r
        $s =~ s/\r//g;
# Заменить пробелы в начале
        $s =~ s/^(\s+)//g;
        $s =~ s#\n( )+\/\/#\n\/\/#g;
# Заменить пробелы в конце
        $s =~ s/( )+\n/\n/g;
# Поставить ровно 1 пробел в начале перед ///
        $s =~ s#( )*\/\/\/# \/\/\/#g;
# схлопнуть {   return 1; }
        $s =~ s#\)\s*\{\s*(return\s*[0-9a-z_])\;\s*\}#\) \{ $1; \}#g;
# выравнивать блоки с : в начале
	@strs = split(/\n/, $s);
	$s_buff = "";
	$s_total = "";
	foreach $str (@strs) {
		if ($str =~ /^ \s*[0-9a-z_\.]+\s*\:\s+/i) { # собрать блок
			$s_buff .="$str\n";
		} else {
			if ($s_buff eq "") {
				$s_total .= "$str\n";
			} else { # расчистить блок
				$s_total .= FixBlockLeft($s_buff, "\:");
				$s_total .= "$str\n";
				$s_buff = "";
			}
		}		
	}
	$s_total .= FixBlockLeft($s_buff, "\:") if ($s_buff ne "");
	$s = $s_total;
# выравнивать блоки с \ на конце
	@strs = split(/\n/, $s);
	$s_buff = "";
	$s_total = "";
	foreach $str (@strs) {
		if ($str =~ /\\$/) { # собрать блок
			$str =~ s/\s*\\$//;
			$s_buff .="$str\n";
		} else {
			if ($s_buff eq "") {
				$s_total .= "$str\n";
			} else { # расчистить блок
				$s_total .= FixBlockRight($s_buff, "\\");
				$s_total .= "$str\n";
				$s_buff = "";
			}
		}		
	}
	$s_total .= FixBlockRight($s_buff, "\\") if ($s_buff ne "");
	$s = $s_total;
# выравнивать блоки с // на конце
	@strs = split(/\n/, $s);
	$s_buff = "";
	$s_total = "";
	foreach $str (@strs) {
		if ($str =~ / \/\//) { # собрать блок
			$s_buff .="$str\n";
		} else {
			if ($s_buff eq "") {
				$s_total .= "$str\n";
			} else { # расчистить блок
				$s_total .= FixBlockMiddle($s_buff, " \/\/");
				$s_total .= "$str\n";
				$s_buff = "";
			}
		}		
	}
	$s_total .= FixBlockMiddle($s_buff, " \/\/") if ($s_buff ne "");
	$s = $s_total;
# выравнивать блоки с : на конце
	@strs = split(/\n/, $s);
	$s_buff = "";
	$s_total = "";
	foreach $str (@strs) {
		if ($str =~ / \:[^ ]/) { # собрать блок
			$s_buff .="$str\n";
		} else {
			if ($s_buff eq "") {
				$s_total .= "$str\n";
			} else { # расчистить блок
				$s_total .= FixBlockMiddle($s_buff, " \:");
				$s_total .= "$str\n";
				$s_buff = "";
			}
		}		
	}
	$s_total .= FixBlockMiddle($s_buff, " \:") if ($s_buff ne "");
	$s = $s_total;
	close(FROMFILE);
# записать результаты
        $s =~ s/\n/\r\n/igs;
# не создавать файл если ничего не изменилось  
	if($s eq $s_old) {
#		print("File was not changed.\n");
		WPrint("");
		return;		
	} else {
		print("\n");
	}
	open(TOFILE, ">temp.tmp") || return "Can't open temp file.";
	binmode(TOFILE);
	print(TOFILE $s); 
	close(TOFILE);
	$bak = $name;
	$bak = substr ($bak, 0, rindex($bak, '.')).".bak";
	if (rename($name, $bak)) {
#		print($name." renamed to ".$bak."\n");
		if (rename ("temp.tmp",$name)) {
#			print("Result saved to ".$name."\n");
			unlink($bak);
		}
	} else {
		print($name." can't be changed. result saved to temp.tmp. ");
	}
}

sub ChangeDir($) {
	my($dir) = @_;
        my (@dirs, @files, $t);
        opendir (DIR,$dir);
       	@dirs=grep {!/^\.+$/ and (-d $dir."/".$_)} readdir DIR;
	closedir DIR;
	foreach $t (@dirs) {
	        ChangeDir($dir."/".$t);
	}
        opendir (DIR,$dir);
        @files = grep {!/^\.+$/ and !(-d "$dir/$_") and ((/\.pnml$/i) || ((/\.lng$/i)))} readdir DIR;
	closedir DIR;
	@files = sort {uc($a) cmp uc($b)} @files;
	foreach $t (@files) {
		ChangeFile($dir."/".$t);
	}
}

sub main()
{
	print("Monalize all pnml files in the current dir and subdirs\n");
        my ($dir);
        use Cwd;
        $dir = cwd();
        $dir =~ s#\\#\/#g;
        $dir =~ s#/$##;
        ChangeDir($dir);
}

main()
#end
