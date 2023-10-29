#!/usr/bin/perl -w
use strict;

# use POSIX;

use utf8;
use open qw(:std :utf8);
#use feature "unicode_strings";
#no bytes;

my(%vehs) = ();
my($vehLongestName) = 0;
my($serName) = "";

sub PrintNSpaces($) {
        my($total) = (@_);                            
	my($res) = ("");
	for(my($i) = 0; $i < $total; $i++) {
		$res .= " ";
	}  
	return $res;
#printf "%${total}s \n", 'A';	         
}                     

sub getFreeID() {
	my($freeID) = 0;
	open(FROMFILE, "<:encoding(UTF-8)", "C\:\\GitHub\\xussrset\\src\\IDs\_usage") || return "XXXX";
	while(<FROMFILE>) {
		chomp;
	        if (/^([0-9]+)\s+\-\>\s+/) {
	        	$freeID = $1 if ($freeID < $1);
	        }
	}
	close(FROMFILE);
	return $freeID + 1;
}

sub CreateGroupFile() {
	my($str) ="";
	$str .= " \/\/ $serName group\n\n";	      	
	$str .= "group_props" . (scalar(keys(%vehs)) - 1) . "(${serName}_group,\n";
# sort according to values, not keys
	my($minval, $first, $groupID) = ("", 1);
	for my $key (sort { $vehs{$a} cmp $vehs{$b} } keys %vehs) {
		if ($first == 1) {
			$str .= "              $key,\n";
			$first = 0;
			$minval = $vehs{$key};
		} else {
			$str .= "              $key," . PrintNSpaces($vehLongestName - length($key) + 1) . "$vehs{$key},\n";
		}
	}
	chop($str);
	chop($str);
	$groupID = getFreeID();
	$str .= "\)\n\n";
	$str .= "item \(FEAT_TRAINS, ${serName}_group, $groupID\) \{\n";
	$str .= "  property \{\n";
	$str .= "    name: string(STR_NAME_". uc($serName) . "_SERIES\)\;\n";
	$str .= "    group_wagon\($minval\, 10\)\n";
	$str .= "  \}\n";
	$str .= "  graphics \{\n";
	$str .= "    group_CBs\(${serName}_group\)\n";
	$str .= "    colour_mapping\: return ttdall_cc \+ 0x49\;\n";
	$str .= "  }\n";
	$str .= "}\n";
	open(TOFILE, ">>:encoding(UTF-8)", "${serName}\-group.pnml") || return "Can't open ${serName}\-group.pnml file.";
	print(TOFILE $str); 
	close(TOFILE);   
}

sub PatchFile($) {
	my($str) = @_;

	my($vehName, $vehCF, $vehRC, $vehSD, $vehWT, $vehTE, $vehPR, $vehCC, $vehLC, $vehStartDate) = ("pe2pe2pe2", 0, 0, 0, 0, 0, 0, 0, 0, 0);
# find id
	$vehName = $1 if ($str =~ /item\s*\(FEAT_TRAINS\,\s*([0-9a-z_]+)\,\s*([0-9]+)\)/i);
	return $str if(not defined($vehName));
	$vehs{$vehName} = "";
	$vehLongestName = length($vehName) if(length($vehName) > $vehLongestName);
# find CF
	$vehCF = $1 if ($str =~ /vehicle_dates\([0-9, ]+,\s*([0-9]+)\)/i);
	$vehStartDate = $1 if ($str =~ /vehicle_dates\(([0-9]+),/i);
	$vehs{$vehName} = $vehStartDate;
# find RC
	$vehRC = $1 if ($str =~ /\{\s*all\_running\_cost\_factor\;\s*\}\s*\/\/\s*([0-9+* ]+)/i);
# find SD and WT
        ($vehSD, $vehWT) = ($2, $1) if ($str =~ /vehicle_wagon\(([0-9\.]+)\,\s*([0-9]+)\)/i);
# find TE
# find PR
# find CC
	my($cc, $tn);
	$vehLC = $1 if ($str =~ /STORE\_TEMP\(([0-9]+)\,\s*0\)\,\s*\/\/\s*т/i); #      
	$tn = $1 if ($str =~ /STORE\_TEMP\(([0-9]+)\,\s*4\)\]\)\s*\/\/\s*шаблон/i); # 
	$tn = $1 if ($str =~ /STORE\_TEMP\(([0-9]+)\,\s*4\)\,\s*\/\/\s*шаблон/i); # 
	$tn = 16 if (not defined($tn));
	$tn = 16 if ($tn == 0);
	$vehCC = ($vehLC * 16 / $tn);
	$vehCC =~ s/\..*$//;
# add PROP block
	$str =~ s/^(.*?)\n/$1\n\n#define PROP_${vehName}_CF  $vehCF\n#define PROP_${vehName}_RC  $vehRC\n#define PROP_${vehName}_SD  $vehSD\n#define PROP_${vehName}_WT  $vehWT\n#define PROP_${vehName}_TE  $vehTE\n#define PROP_${vehName}_PR  $vehPR\n#define PROP_${vehName}_CC  $vehCC\n#define PROP_${vehName}_LC  $vehLC\n/s;
# add name
	my($vehNameUC, $serNameUC, $tmp, $lang, $model);
	$vehNameUC = uc ($vehName);
	$serNameUC = uc ($serName);
	$tmp = PrintNSpaces(length($vehName));
	$lang = "";
	$lang = "LONG" if ($str =~ /long_name_template/i);
	$model = "string(STR_NAME_${vehNameUC})";
	$model = $1 if ($str =~ /(string\(STR_MODEL_NUMBER2\,\s*[0-9]+\,\s*[0-9]+\))/i);
	$model = $1 if ($str =~ /(string\(STR_MODEL_NUMBER3\,\s*[0-9]+\,\s*[0-9]+,\s*[0-9]+\))/i);
        $str =~ s/hint_wagon/name_in_group(${vehName}, string(STR_NAME_IN_GROUP, string(STR_NAME_${serNameUC}_SERIES), $model),\n                ${tmp}string(STR_NAME_IN_GROUP, string(STR_NAME_${serNameUC}_SERIES), string(STR_${lang}NAME_${vehNameUC})))\n\nhint_wagon/i;
# add name CB
        $str =~ s/graphics \{/graphics \{\n    purchase_menu_wagon\(PROP_${vehName}_CF, PROP_${vehName}_RC, PROP_${vehName}_SD, PROP_${vehName}_WT, PROP_${vehName}_TE, PROP_${vehName}_PR, PROP_${vehName}_LC\)\n    name\: ${vehName}_name;/i;
# replace rc
        $str =~ s/STORE_TEMP\([0-9]+\,\s*6\)\,\s*\/\/\s*Скорость/STORE_TEMP\(PROP_${vehName}_SD\, 6\)\, \/\/ Скорость/;
        $str =~ s/STORE_TEMP\([0-9]+\,\s*7\)\,\s*\/\/\s*Тара/STORE_TEMP\(round\(PROP_${vehName}_WT\)\, 7\)\, \/\/ Тара/;
        $str =~ s/STORE_TEMP\(.*?\,\s*8\)\]\)\s*\/\/\s*Максимальная масса/STORE_TEMP\(round\(PROP_${vehName}_WT + PROP_${vehName}_LC\)\, 8\)\]\) \/\/ Максимальная масса/;
# replace rc
        $str =~ s/vehicle_dates\(([0-9, ]+)\,\s*[0-9]+\)/vehicle_dates\($1, PROP_${vehName}_CF\)/i;
# replace wt sd
        $str =~ s/vehicle_wagon\([0-9\.]+\,\s*[0-9]+\)/vehicle_wagon\(PROP_${vehName}_WT\, PROP_${vehName}_SD\)\n    vehicle_group\(${serName}_group\)/i;
# replace lc
        $str =~ s/\[\s*STORE_TEMP\([0-9]+\, 0\)\,\s*\/\/\s*т/\[  STORE_TEMP\(PROP_${vehName}_LC\, 0\)\,  \/\/ т/i;

	return($str);
}

sub ChangeFile($) {
	my($name) = @_;
	my($bak, $s, $s_old);
	my(@strs);
	my($s_buff, $s_total, $str);

	open(FROMFILE, "<:encoding(UTF-8)", $name) || return "Can't open: ".$name;
	$s = join("", <FROMFILE>);
	close(FROMFILE);
	$s_old = $s;
	print("Changing $name\n");
	$s = PatchFile($s);
# записать результаты
# не создавать файл если ничего не изменилось  
	if($s eq $s_old) {
		print("File was not changed.\n");
		return;		
	} else {
		print("\n");
	}
	open(TOFILE, ">:encoding(UTF-8)", "temp.tmp") || return "Can't open temp file.";
	print(TOFILE $s); 
	close(TOFILE);
	$bak = $name;
	$bak = substr ($bak, 0, rindex($bak, '.')).".bak";
	if (rename($name, $bak)) {
		if (rename ("temp.tmp",$name)) {
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
        @files = grep {!/^\.+$/ and !(-d "$dir/$_") and (/\.pnml$/i)} readdir DIR;
	closedir DIR;
	@files = sort {uc($a) cmp uc($b)} @files;
	foreach $t (@files) {
		ChangeFile($dir."/".$t);
	}
}

sub main()
{
	print("Add props block to all pnml files in the current dir\n");
	$serName = $ARGV[0];
	$serName = "" if (not defined($serName));
	if ($serName eq "") {
		die("Group name required!\n");
	}
	my ($dir);
        use Cwd;
        $dir = cwd();
        $dir =~ s#\\#\/#g;
        $dir =~ s#/$##;
        ChangeDir($dir);
        CreateGroupFile();
}

main()
#end
