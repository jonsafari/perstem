#!/usr/bin/perl
# Written by Jon Dehdari 2004-2005
# Perl 5.8
# Stemmer and Morphological Parser for Persian
# The license is the GPL v.2 or later (www.fsf.org)

# The format of the resolve.txt file is as follows:
# 1. Mokassar: 		'ktb	ktAb'    OR    'ktb	ktAb_+PL'
# 2. Preparsed (speed):	'krdn	kr_+dn'
# 3. Don't stem:	'bArAn	bArAn'
# 4. Stop word:		'u	'


use strict;
use utf8;
#use diagnostics;
#binmode(STDOUT, ":utf8");
#use LWP::Simple qw(!head);
use CGI qw(:standard); #must use this full line, not just CGI
use CGI::Carp;
#use CGI::Carp qw(fatalsToBrowser);
$CGI::POST_MAX=50000;
my $query = new CGI;

my $input_type      = param ("input_type");
my $output_type     = param ("output_type");
my $remove_stops    = param ("remove_stops");
my $root_only       = param ("root_only");
my $preserve_links  = param ("preserve_links");
my $use_web_page    = param ("use_web_page");
my $web_page        = param ("web_page");
my $use_file        = param ("use_file");
my $uploaded_file   = param ("uploaded_file");
my $text_from       = param ("text_from");
#my $input_type     = "1";
#my $text_from      = "\u{d986}\u{d8a7}\u{d986}\u{d987}\u{d8a7}";
#my $text_from      = "\u{0646}\u{0627}\u{0646}\u{0647}\u{0627}";
#my $text_from      = "&#1606;&#1575;&#1606;&#1607;&#1575;";
#my $text_from      = "قدومي بفارغ الصبر";
#my $preserve_links = 0;
#my $use_file       = "false";
#my $uploaded_file  = "false";
#my $use_web_page   = "false";
#my $web_page       = "false";
#my $remove_stops   = "false";
my %unicode2roman;
my $text_from_new;
my @charx;
my $charx;
my $input_rtl;
my $resolve_file;
my %resolve;
my @resolve;
my $resolve;
#my $ar_chars    = "EqHSTDZLVU";
#my $longvowel    = "Aui]";

if ($input_type =~ /[^0]/) { $input_rtl = "true"; }

if ($remove_stops eq "true") {$resolve_file = "resolve.txt"; }
if ($remove_stops ne "true") {$resolve_file = "resolve_no_stops.txt"; }

if ($input_type eq "utf8" || $output_type eq "utf8") { print $query->header( -charset => 'UTF-8'); }
else {  print $query->header( -charset => 'windows-1256'); }


print( 
	'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//FA">',
	"\n",
	'<html lang="fa">',
	"\n",
	"\n",
#	"<style>\n",
#	"    body \{ text-align\:right \}\n",
#	"<\/style>\n",
	"<head>\n",
);
if ($input_type eq "utf8" || $output_type eq "utf8") { print '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'; }
if ($input_type eq "cp1256") { print '<meta http-equiv="Content-Type" content="text/html; charset=windows-1256">'; }
print(
        "\n",
	"<title>Persian Stemmer and Morphological Analyzer<\/title>\n",
	"<\/head>\n",
	"<body>\n",
        '<table width="100%" border="1" cellspacing="0" cellpadding="9">',
        "\n",
        "  <tr>\n",
);

# For getting web page stuff; requires LWP::Simple module
if ($use_web_page eq "--noroman") {
$text_from = "";  # Clears out residue from the web form
#$text_from = get "$web_page";
print('</td>
     <td width="100%">
');
#print("$text_from");
}


elsif ($use_file eq "true") {
$text_from = "";  # Clears out residue from the web form
print('</td>
     <td width="100%">
');
while (my $line = <$uploaded_file> ) {
$text_from = $text_from . $line ;
}
#if (length $text_from > 40000 ) {
#  die "Your uploaded file is too big.<br/></td></tr></table></html>\n";
#}
}

if ($use_web_page ne "--noroman" && $use_file ne "true") {
my $formated_text_from = "$text_from";
$formated_text_from =~ s/\n/<br\/>\n/g; #changes newline to <br>for from text
if ($input_rtl eq "true") { print("   <td width=\"50%\" align=\"right\"><br/>\n"); }
else { print("   <td width=\"50%\"><br/>\n"); }
print("$formated_text_from");
print('
   </td>'); # closes from text side (left side)

#Prints second column, the one with the new stuff
print('
   <td width="50%">
'); 
}


$text_from =~ s/(?<!\&#\w{4})[;]/ _$1_ /g; #Preserves punctuation for semicolon except for unicode decimal &#....;
$text_from =~ s/([.,?!])/ _$1_ /g; #Preserves punctuation
$text_from =~ s/\brm\b|passwd|shadow|\bmv\b//g; # some security stuff


chomp $text_from;
my $word;
#print "text_from: $text_from<br>";

$word =  `echo  \"$text_from  \" | ~/public_html/perstem.pl -u $preserve_links $root_only $use_web_page -i $input_type -o $output_type 2>/dev/null ` or carp "perstem.pl didn't work" ;


##### End #####
    $word =~ s/_([.,;?!])_/$1/g;

    $word =~ s/\n/<br\/>\n/g;
    print "$word ";

#} # ends foreach (@word)
=cut

print( "\n<br\/>\n<\/td><\/tr><\/table>\n<\/body>\n<\/html>\n");
