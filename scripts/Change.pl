#!/usr/bin/perl
use strict;
use warnings;

sub clean($$$) {
	my($name,$str1,$str2) = (@_);
	my($s, $r) = ("", "");
#if (!(define ($name)))
# if ($str2 eq "") {die("No second string.\n");};
#$str1=~s#\\n#\n#ig;
#$str1=~s#\\r#\r#ig;
#$str1=~s#\\t#\t#ig;
#$str2=~s#\\n#\n#ig;
#$str2=~s#\\r#\r#ig;
#$str2=~s#\\t#\t#ig;
$r='$s =~ s#'.$str1.'#'.$str2.'#isg;';

print("File name: ".$name);
print("\nFirst string: ".$str1);
print("\nSecond string: ".$str2);
print("\nRegexp: ".$r."\n");

	 open(FROMFILE, "<".$name) || die ("Cant open: ".$name);
	 open(TOFILE, ">temp.tmp") || die ("Cant open temp file. ");
	 binmode(FROMFILE);
	 binmode(TOFILE);
	 $s=join("", <FROMFILE>);
	 eval  $r ;  
	 print ("Error:".$@."\n") if ($@ ne "");
	 print (TOFILE $s); 
	 close (TOFILE);
	 close (FROMFILE);

$_=$name;
$_=substr($_,0,rindex($_,'.')).".bak";
if (rename ($name,$_))
  {print($name." renamed to ".$_."\n");
   if (rename ("temp.tmp",$name))
     {print("Result saved to ".$name."\n");}}
 else
  {print($name." can't be changed. result saved to temp.tmp. ");};
}

sub main() {
	my($name, $str1, $str2);
	$name = $ARGV[0];
	$str1 = $ARGV[1];
	$str2 = $ARGV[2];

	$name = "" if(not defined($name));
	if(-e $name && (not -d $name)) {
		$str1 = "" if(not defined($str1));
		$str2 = "" if(not defined($str2));
		if ($str1 eq "") {
			print("No first string.\n");
		} else {
			clean($name, $str1, $str2);
		}
	} else {
		print("Can't change $name\n");
	}
}

main();
