#!/usr/bin/perl 

use strict;
use warnings;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Win32::Console::ANSI;
use Term::ANSIScreen qw/:color /;
use Term::ANSIScreen qw(cls);
use Time::HiRes;
use Fcntl qw(:flock :seek);
use String::HexConvert ':all';
use Win32::Console;
use File::Copy qw(copy);
use Regexp::Assemble;

##############################################################################################################################################
# __________        __    __                __      __               ___________.__                 __                       .__               
# \______   \ _____/  |__/  |_  ___________/  \    /  \_____  ___.__.\_   _____/|  |   ____   _____/  |________  ____   ____ |__| ____   ______
 # |    |  _// __ \   __\   __\/ __ \_  __ \   \/\/   /\__  \<   |  | |    __)_ |  | _/ __ \_/ ___\   __\_  __ \/  _ \ /    \|  |/ ___\ /  ___/
 # |    |   \  ___/|  |  |  | \  ___/|  | \/\        /  / __ \\___  | |        \|  |_\  ___/\  \___|  |  |  | \(  <_> )   |  \  \  \___ \___ \ 
 # |______  /\___  >__|  |__|  \___  >__|    \__/\  /  (____  / ____|/_______  /|____/\___  >\___  >__|  |__|   \____/|___|  /__|\___  >____  >
        # \/     \/                \/             \/        \/\/             \/           \/     \/                        \/        \/     \/ 

##############################################################################################################################################


my $CONSOLE=Win32::Console->new;
$CONSOLE->Title('BwE PS4 NOR Extractor');

my $clear_screen = cls(); 
my $osok = (colored ['bold green'], "OK");
my $osdanger = (colored ['bold red'], "DANGER");
my $oswarning = (colored ['bold yellow'], "WARNING");
my $osunlisted = (colored ['bold blue'], "UNLISTED");

my $BwE = (colored ['bold magenta'], qq{
===========================================================
|            __________          __________               |
|            \\______   \\ __  _  _\\_   ____/               |
|             |    |  _//  \\/ \\/  /|  __)_                |
|             |    |   \\\\        //       \\               |
|             |______  / \\__/\\__//______  /               |
|                    \\/PS4 NOR EXTRACTOR\\/v1.3            |
|        		                                  |
===========================================================\n});
print $BwE;

START:

############################################################################################################################################

my @files=(); 

while (<*.bin>) 
{
    push (@files, $_) if (-s eq "33554432");
}

my $input; my $file; my $original;

if ( @files == 0 ) {
	print "\n$oswarning: Nothing to extract. Aborting...\n"; 
	goto FAILURE;
} else {

if ( @files > 1 ) { 
	print "\nMultiple .bin files found within the directory:\n\n";
	foreach my $file (0..$#files) {
		print $file + 1 . " - ", "$files[$file]\n";
}

print "\nPlease make a selection: ";
my $input = <STDIN>; chomp $input; 
my $nums = scalar(@files);

if ($input > $nums) {
	print "\n\n$oswarning: Selection out of range. Aborting...\n\n"; 
	goto FAILURE;}
	
elsif ($input eq "0") {
	print "\n\n$oswarning: Selection out of range. Aborting...\n\n"; 
	goto FAILURE;}
	
elsif ($input eq "") {
	print "\n\n$oswarning: You didn't select anything. Aborting...\n\n"; 
	goto FAILURE;} else {
		$file = $files[$input-1]; 
		$original = $files[$input-1];}; 
	
} else { 
$file = $files[0]; 
$original = $file = $files[0];}
}

### Now that the file is selected....

open(my $bin, "<", $file) or die $!; binmode $bin;

my $md5sum = uc Digest::MD5->new->addfile($bin)->hexdigest; 
my $size= -s $bin;
if ($size ne "33554432") { print "\n\n$osdanger: $file is the wrong size ($size). Aborting...\n\n"; goto FAILURE} else {};

seek($bin, 0x0, 0);read($bin, my $bytereversed, 0x20); my $reversedstatus; 
if ($bytereversed eq "OSYNC MOUPET RNEETTRIAMNNE TNI.C") { $reversedstatus = "Yes"; } else { $reversedstatus = "No"; };

seek($bin, 0x1C8041,0);read($bin, my $whatisthesku, 0xE); $whatisthesku =~ tr/a-zA-Z0-9 -//dc; #Hahahaha! Easy!

##########################################

my $whatistheversion;

seek($bin, 0x1C906A, 0); 
read($bin, my $FW_Version2, 0x2);
$FW_Version2 = uc ascii_to_hex($FW_Version2); 
if ($FW_Version2 eq "FFFF")
{
	seek($bin, 0x1CA606, 0); 
	read($bin, my $FW_Version1, 0x2);
	$FW_Version1 = uc ascii_to_hex($FW_Version1); 
	if ($FW_Version1 eq "FFFF")
	{
		$whatistheversion = "N/A";
	} 
	else
	{
		$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
		$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
		$whatistheversion = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
	}
} 
else
{
	$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
	$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
	$whatistheversion = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
	
}

##########################################

print $clear_screen;
	print $BwE;

	(my $fileminusbin = $file) =~ s/\.[^.]+$//;
	print "\nExtracting '$file' Zecoxao Style....\n\n"; 

	my $extract;
	mkdir $fileminusbin."_Extracted";
	open(F,'>', $fileminusbin."_MD5.txt") || die $!;
	
my $BwE2 = qq{
===========================================================
|            __________          __________               |
|            \\______   \\ __  _  _\\_   ____/               |
|             |    |  _//  \\/ \\/  /|  __)_                |
|             |    |   \\\\        //       \\               |
|             |______  / \\__/\\__//______  /               |
|                    \\/PS4 NOR EXTRACTOR\\/v1.3            |
|        		                                          |
===========================================================\n\n};
print F $BwE2;

print F "Filename: $file\n";
print F "File Size: $size\n";
print F "SKU: $whatisthesku\n";
print F "Version: $whatistheversion\n";
print F "MD5: $md5sum\n";

print F "\n===========================================================";

##########################################

print "Header\n";
print F "\n\nHeader\n";
open($extract, '+>', $fileminusbin."_Extracted/1_Header.bin") or die $!; binmode($extract);
seek($bin, 0x0000, 0); 
read($bin, my $zecoxao_header, 0x1000);
print $extract $zecoxao_header;
print uc md5_hex($zecoxao_header);
print F uc md5_hex($zecoxao_header);

##########################################

print "\n\nUnk\n";
print F "\n\nUnk\n";
open($extract, '+>', $fileminusbin."_Extracted/2_Unk.bin") or die $!; binmode($extract);
seek($bin, 0x1000, 0); 
read($bin, my $zecoxao_Unk, 0x1000);
print $extract $zecoxao_Unk;
print uc md5_hex($zecoxao_Unk);
print F uc md5_hex($zecoxao_Unk);

##########################################

print "\n\nMBR1 for sflash0s1.cryptx3b\n";
print F "\n\nMBR1 for sflash0s1.cryptx3b\n";
open($extract, '+>', $fileminusbin."_Extracted/3_MBR1.bin") or die $!; binmode($extract);
seek($bin, 0x2000, 0); 
read($bin, my $zecoxao_MBR1, 0x1000);
print $extract $zecoxao_MBR1;
print uc md5_hex($zecoxao_MBR1);
print F uc md5_hex($zecoxao_MBR1);

##########################################

print "\n\nMBR2 for sflash0s1.cryptx3\n";
print F "\n\nMBR2 for sflash0s1.cryptx3\n";
open($extract, '+>', $fileminusbin."_Extracted/4_MBR2.bin") or die $!; binmode($extract);
seek($bin, 0x3000, 0); 
read($bin, my $zecoxao_MBR2, 0x1000);
print $extract $zecoxao_MBR2;
print uc md5_hex($zecoxao_MBR2);
print F uc md5_hex($zecoxao_MBR2);

##########################################

print "\n\nEMC_IPL for sflash0s0x32b\n";
print F "\n\nEMC_IPL for sflash0s0x32b\n";
open($extract, '+>', $fileminusbin."_Extracted/5_EMC_IPL.bin") or die $!; binmode($extract);
seek($bin, 0x4000, 0); 
read($bin, my $zecoxao_EMC_IPL, 0x60000);
print $extract $zecoxao_EMC_IPL;
print uc md5_hex($zecoxao_EMC_IPL);
print F uc md5_hex($zecoxao_EMC_IPL);

##########################################

print "\n\nEMC_IPL for sflash0s0x32\n";
print F "\n\nEMC_IPL for sflash0s0x32\n";
open($extract, '+>', $fileminusbin."_Extracted/6_EMC_IPL_2.bin") or die $!; binmode($extract);
seek($bin, 0x64000, 0); 
read($bin, my $zecoxao_EMC_IPL2, 0x60000);
print $extract $zecoxao_EMC_IPL2;
print uc md5_hex($zecoxao_EMC_IPL2);
print F uc md5_hex($zecoxao_EMC_IPL2);

##########################################

print "\n\nEAP_KBL for sflash0s0x33\n";
print F "\n\nEAP_KBL for sflash0s0x33\n";
open($extract, '+>', $fileminusbin."_Extracted/7_EAP_KBL.bin") or die $!; binmode($extract);
seek($bin, 0xC4000, 0); 
read($bin, my $zecoxao_EAP_KBL, 0x80000);
print $extract $zecoxao_EAP_KBL;
print uc md5_hex($zecoxao_EAP_KBL);
print F uc md5_hex($zecoxao_EAP_KBL);

##########################################

print "\n\nWIFI_BT for sflash0s0x34\n";
print F "\n\nWIFI_BT for sflash0s0x34\n";
open($extract, '+>', $fileminusbin."_Extracted/8_WIFI_BT.bin") or die $!; binmode($extract);
seek($bin, 0x144000, 0); 
read($bin, my $zecoxao_WIFI_BT, 0x80000);
print $extract $zecoxao_WIFI_BT;
print uc md5_hex($zecoxao_WIFI_BT);
print F uc md5_hex($zecoxao_WIFI_BT);

##########################################

print "\n\nNVS for sflash0s0x38\n";
print F "\n\nNVS for sflash0s0x38\n";
open($extract, '+>', $fileminusbin."_Extracted/9_NVS.bin.bin") or die $!; binmode($extract);
seek($bin, 0x1C4000, 0); 
read($bin, my $zecoxao_NVS, 0xC000);
print $extract $zecoxao_NVS;
print uc md5_hex($zecoxao_NVS);
print F uc md5_hex($zecoxao_NVS);

##########################################

print "\n\nBlank 1 for sflash0s0x0\n";
print F "\n\nBlank 1 for sflash0s0x0\n";
open($extract, '+>', $fileminusbin."_Extracted/10_Blank1.bin") or die $!; binmode($extract);
seek($bin, 0x1D0000, 0); 
read($bin, my $zecoxao_BLANK1, 0x30000);
print $extract $zecoxao_BLANK1;
print uc md5_hex($zecoxao_BLANK1);
print F uc md5_hex($zecoxao_BLANK1);

##########################################

print "\nHeader 2\n";
print F "\n\nHeader 2\n";
open($extract, '+>', $fileminusbin."_Extracted/11_Header2.bin") or die $!; binmode($extract);
seek($bin, 0x200000, 0); 
read($bin, my $zecoxao_header2, 0x1000);
print $extract $zecoxao_header2;
print uc md5_hex($zecoxao_header2);
print F uc md5_hex($zecoxao_header2);

##########################################

print "\n\nUnk 2\n";
print F "\n\nUnk 2\n";
open($extract, '+>', $fileminusbin."_Extracted/12_Unk2.bin") or die $!; binmode($extract);
seek($bin, 0x201000, 0); 
read($bin, my $zecoxao_Unk2, 0x1000);
print $extract $zecoxao_Unk2;
print uc md5_hex($zecoxao_Unk2);
print F uc md5_hex($zecoxao_Unk2);

##########################################

print "\n\nMBR3 for sflash0s1.cryptx2b\n";
print F "\n\nMBR3 for sflash0s1.cryptx2b\n";
open($extract, '+>', $fileminusbin."_Extracted/13_MBR3.bin") or die $!; binmode($extract);
seek($bin, 0x202000, 0); 
read($bin, my $zecoxao_MBR3, 0x1000);
print $extract $zecoxao_MBR3;
print uc md5_hex($zecoxao_MBR3);
print F uc md5_hex($zecoxao_MBR3);

##########################################

print "\n\nMBR4 for sflash0s1.cryptx2\n";
print F "\n\nMBR4 for sflash0s1.cryptx2\n";
open($extract, '+>', $fileminusbin."_Extracted/14_MBR4.bin") or die $!; binmode($extract);
seek($bin, 0x203000, 0); 
read($bin, my $zecoxao_MBR4, 0x1000);
print $extract $zecoxao_MBR4;
print uc md5_hex($zecoxao_MBR4);
print F uc md5_hex($zecoxao_MBR4);

##########################################

print "\n\nSAM_IPL/Secure Loader for sflash0s1.cryptx2b\n";
print F "\n\nSAM_IPL/Secure Loader for sflash0s1.cryptx2b\n";
open($extract, '+>', $fileminusbin."_Extracted/15_SAM_IPL_SEC_LDR.bin") or die $!; binmode($extract);
seek($bin, 0x204000, 0); 
read($bin, my $zecoxao_SAM_IPL_SEC_LDR, 0x3E000);
print $extract $zecoxao_SAM_IPL_SEC_LDR;
print uc md5_hex($zecoxao_SAM_IPL_SEC_LDR);
print F uc md5_hex($zecoxao_SAM_IPL_SEC_LDR);

########################################## 

print "\n\nSAM_IPL/Secure Loader for sflash0s1.cryptx2\n";
print F "\n\nSAM_IPL/Secure Loader for sflash0s1.cryptx2\n";
open($extract, '+>', $fileminusbin."_Extracted/16_SAM_IPL_SEC_LDR2.bin") or die $!; binmode($extract);
seek($bin, 0x242000, 0); 
read($bin, my $zecoxao_SAM_IPL_SEC_LDR2, 0x3E000);
print $extract $zecoxao_SAM_IPL_SEC_LDR2;
print uc md5_hex($zecoxao_SAM_IPL_SEC_LDR2);
print F uc md5_hex($zecoxao_SAM_IPL_SEC_LDR2);

##########################################

print "\n\nIDATA for sflash0s1.cryptx1\n";
print F "\n\nIDATA for sflash0s1.cryptx1\n";
open($extract, '+>', $fileminusbin."_Extracted/17_IDATA.bin") or die $!; binmode($extract);
seek($bin, 0x280000, 0); 
read($bin, my $zecoxao_IDATA, 0x80000);
print $extract $zecoxao_IDATA;
print uc md5_hex($zecoxao_IDATA);
print F uc md5_hex($zecoxao_IDATA);

##########################################

print "\n\nBD_HRL for sflash0s1.cryptx39\n";
print F "\n\nBD_HRL for sflash0s1.cryptx39\n";
open($extract, '+>', $fileminusbin."_Extracted/18_BD_HRL.bin") or die $!; binmode($extract);
seek($bin, 0x300000, 0); 
read($bin, my $zecoxao_BD_HRL, 0x80000);
print $extract $zecoxao_BD_HRL;
print uc md5_hex($zecoxao_BD_HRL);
print F uc md5_hex($zecoxao_BD_HRL);

##########################################

print "\n\nVTRM for sflash0s1.cryptx6\n";
print F "\n\nVTRM for sflash0s1.cryptx6\n";
open($extract, '+>', $fileminusbin."_Extracted/19_VTRM.bin") or die $!; binmode($extract);
seek($bin, 0x380000, 0); 
read($bin, my $zecoxao_VTRM, 0x40000);
print $extract $zecoxao_VTRM;
print uc md5_hex($zecoxao_VTRM);
print F uc md5_hex($zecoxao_VTRM);

##########################################

print "\n\nSecure Kernel & Modules for sflash0s1.cryptx3b\n";
print F "\n\nSecure Kernel & Modules for sflash0s1.cryptx3b\n";
open($extract, '+>', $fileminusbin."_Extracted/20_SEC_Kernel.bin") or die $!; binmode($extract);
seek($bin, 0x3C0000, 0); 
read($bin, my $zecoxao_SEC_Kernel, 0xCC0000);
print $extract $zecoxao_SEC_Kernel;
print uc md5_hex($zecoxao_SEC_Kernel);
print F uc md5_hex($zecoxao_SEC_Kernel);

##########################################

print "\n\nSecure Kernel & Modules 2 for sflash0s1.cryptx3\n";
print F "\n\nSecure Kernel & Modules 2 for sflash0s1.cryptx3\n";
open($extract, '+>', $fileminusbin."_Extracted/21_SEC_Kernel2.bin") or die $!; binmode($extract);
seek($bin, 0x1080000, 0); 
read($bin, my $zecoxao_SEC_Kernel2, 0xCC0000);
print $extract $zecoxao_SEC_Kernel2;
print uc md5_hex($zecoxao_SEC_Kernel2);
print F uc md5_hex($zecoxao_SEC_Kernel2);
	
##########################################

print "\n\nBlank 2 for sflash0s1.cryptx40\n";
print F "\n\nBlank 2 for sflash0s1.cryptx40\n";;
open($extract, '+>', $fileminusbin."_Extracted/22_Blank2.bin") or die $!; binmode($extract);
seek($bin, 0x1D40000, 0); 
read($bin, my $zecoxao_Blank2, 0x2C0000);
print $extract $zecoxao_Blank2;
print uc md5_hex($zecoxao_Blank2);
print F uc md5_hex($zecoxao_Blank2);

##########################################

print F "\n\n===========================================================\n\n";

close(F); 

color 'black on green';
print qq{\n\nExtraction of $file Complete!\n\n}; 
color 'reset';

my $opensysfile = system($fileminusbin."_MD5.txt");

##########################################

print "Continue? (y/n): "; 
$input = <STDIN>; chomp $input; 
if ($input eq "n") { goto FAILURE } else { goto START };


FAILURE:

print "\nPress Enter to Exit... ";
while (<>) {
chomp;
last unless length;
}