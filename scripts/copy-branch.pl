#!perl
use strict;

use locale;
use POSIX qw (locale_h);
use Encode;

my($todir) = ('c:/YandexDisk/My/-todelete/xUSSRset/'); 
if(defined($ENV{"YDPATH"}) && 
   ($ENV{"YDPATH"} ne "") &&
   (-e $ENV{"YDPATH"}) &&
   (-d $ENV{"YDPATH"}) ) {
   	print("Change path to ");
	$todir = $ENV{"YDPATH"};
   	print("Change path to \"$todir\"\n");
	$todir =~ s/\\/\//g;
	$todir =~ s/\/$//;
 	$todir .= '/';
}

sub MMkdir($)
{
	my($dir,$i,$tmp,@sd)=@_;
	$dir=~s/\/$//;
	my($prefix)='';
	if ($dir=~s/^(\/\/[^\/]+\/)//) {
		$prefix=$1; 
	} elsif ($dir=~s/^([a-z]\:[\\\/])//i) { 
		$prefix=$1; 
	}	
	@sd=split(/\//,$dir);
	for($i=0;$i<=$#sd;$i++)
	{
		$tmp=$prefix.join('/',@sd[0..$i]);
		mkdir($tmp);
		print "Error creating $dir (Pref: $prefix, Dir: $tmp) - $!\n" if ($! ne "" and !($!=~/^file\s*exists$/i));
	}
}

sub main() {
	my($name, $tname, $nver, $ver, $str, $branch);
	$name = $ARGV[0];
	$name = "" if(not defined($name));
	if(not -e $name || -d $name) {
		print("\"$name\" does not exist\n$!\n");	
		exit(1);
	}			
	print("Copy $name");
	$nver = $name;
	$nver =~ s/\.grf$/\.ver/isg;
	if(-e $nver) {
		if(not open(FROMFILE, "<:encoding(UTF-8)", $nver)) {
			$ver = "";
		} else {
			$ver = join("", <FROMFILE>);
			$ver =~ s/^.*?([0-9]+).*$/$1/isg;
		}		
	} else {
		$ver = "";
	}
#print("To $todir\n");
	if(not open(FROMFILE, "<:encoding(UTF-8)", "\.git\/HEAD")) {
		print("Can't read branch name.\n$!\n");	
		exit(1);
	}
	$str = join("", <FROMFILE>);
	close(FROMFILE);
	if($str =~ /ref\:\s*refs\/heads\/([^\s]+)/is) {
		$branch = $1;
# записано в utf-8, надо сконвертировать
		Encode::from_to($branch,'utf8','cp1251');
#		$branch = "" if($branch eq "main");
		$branch = $todir.$branch;
		print(" to $branch\n");
		MMkdir($branch);
		use File::Copy;
		$tname = $branch."\/";
#		$tname .= $ver."\.";
		$tname .= $name;
		if(-e $tname) {
			unlink($tname);
		}
		if(not copy($name, $tname)) {
			print("Can't copy $name to $tname\n$!\n");	
			exit(1);		
		}	
	}	
}

main();
