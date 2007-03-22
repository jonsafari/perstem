#!/usr/bin/perl
# Written by Jon Dehdari 2004-2007
# Perl 5.8
# Perstem:  Stemmer and Morphological Parser for Persian
# The license is the GPL v.2 (www.fsf.org)
# Usage:  perl perstem.pl [options] < input > output
# Issues: punctuation vs tokenization

use strict;
#use warnings;
#use diagnostics;
use Getopt::Long;

my $version        = "0.9.4";
my $date           = "2007-03-22";
my $copyright      = "(c) 2004-2007  Jon Dehdari - GPL v2";
my $title          = "Perstem: Persian stemmer $version, $date - $copyright";
my ( $dont_stem, $input_type, $output_type, $no_roman, $recall, $show_links, $show_only_root, $tokenize, $unvowel, $zwnj )  = undef; 
my $ar_chars       = "EqHSTDZLVU";
#my $al             = "AbptVjcHxdLrzJsCSDTZEGfqkglmnuhiaoe\x5d\x7cPkMXIUN~";
#my $longvowel     = "Aui]";
my %resolve;

my $usage       = <<"END_OF_USAGE";
${title}

Usage:    perl $0 [options] < input > output

Function: Stemmer and morphological analyzer for the Persian language (Farsi).
          Inflexional morphemes are separated from their roots.

Options:
  -d, --nostem           Don't stem -- mostly for character-set conversion
  -h, --help             Print usage
  -i, --input <type>     Input character encoding type {cp1256,isiri3342,utf8,unihtml}
  -l, --links            Show morphological links
  -n, --noroman          Delete all non-Arabic script characters (eg. HTML tags)
  -o, --output <type>    Output character encoding type {arabtex,cp1256,isiri3342,utf8,unihtml}
  -r, --recall           Increase recall by parsing ambiguous affixes
  -t, --tokenize         Tokenize punctuation
  -u, --unvowel          Remove short vowels
  -v, --version          Print version ($version)
  -w, --root             Return only word roots
  -z, --zwnj             Insert Zero Width Non-Joiners where they should be

END_OF_USAGE
#  -s, --stoplist <file>   Use external stopword list <file>

GetOptions(
    'd|nostem'      => \$dont_stem,
    'h|help|?'      => sub { print $usage; exit; },
    'i|input:s'     => \$input_type,
    'l|links'       => \$show_links,
    'n|noroman'     => \$no_roman,
    'o|output:s'    => \$output_type,
    'r|recall'	    => \$recall,
#    's|stoplist:s'  => \$resolve_file,
    't|tokenize'    => \$tokenize,
    'u|unvowel'     => \$unvowel,
    'v|version'     => sub { print "$version\n"; exit; },
    'w|root'        => \$show_only_root,
    'z|zwnj'        => \$zwnj,
) or die $usage;

$input_type  and $input_type  =~ s/.*1256/cp1256/; # equates win1256 with cp1256
$output_type and $output_type =~ s/.*1256/cp1256/; # equates win1256 with cp1256
$input_type  and $input_type  =~ tr/[A-Z]/[a-z]/;  # recognizes more enctype spellings
$output_type and $output_type =~ tr/[A-Z]/[a-z]/;  # recognizes more enctype spellings
$input_type  and $input_type  =~ tr/-//;           # eg. UTF-8 & utf8
$output_type and $output_type =~ tr/-//;           # eg. UTF-8 & utf8


### Open Resolve section
while (my $resolve = <DATA>) {
    next if $resolve =~ /^#/;
    chomp $resolve;
    my @resolve = split /\t/, $resolve;
    %resolve = ( %resolve, "$resolve[0]" => "$resolve[1]" , );
}


### A hack for what Perl should've already done: support at runtime BOTH utf8 & other input types
if ($input_type and $input_type eq "utf8") { # UTF-8
 use encoding "utf8";
 open STDIN, "<:encoding(UTF-8)" ; 
}
else { unimport encoding "utf8";}
 

while ($_ = <> ) {
next if ( /^$/ | /^\s+$/ | /^#/ );  # Skips empty or commented-out lines
$_ =~ tr/\r/\n/d;   # Deletes lame DOS carriage returns
$_ =~ s/\n/ ==20==/; # Converts newlines to temporary placeholder ==20== (after \x20)

@_ = split(/(?<!mi)\s+(?!hA)/);
foreach (@_) {

### Converts from native script to romanized
if ($input_type) {

 if ($no_roman) {
  $_ =~ s/<br>/\n/g;
  $_ =~ s/<p>/\n/g;
  $_ =~ tr/\x01-\x09\x1b-\x1f\x21-\x2d\x2f-\x5a\x5c\x5e-\x9f//d; # Deletes all chars below xa0 except: 0a,20,2e,5b,5d
#  $_ =~ s/<\.>//g;  # Deletes all dots in HTML tags
#  $_ =~ s/<.*?>//g; # Deletes all HTML tags on 1 line
#  $_ =~ s/<.*?//g;  # Deleses 1st part of line-spanning HTML tags
#  $_ =~ s/.*?>//g;  # Deletes 2nd part of line-spanning HTML tags
 }

 if ($input_type eq "utf8") {
  $_ =~ tr/ابپتثجچحخدذرزژسشصضطظعغفقكگلمنوهيَُِآ☿ةکیءىۀئؤًّ،؛؟٪‍‌/AbptVjcHxdLrzJsCSDTZEGfqkglmnuhiaoe\x5d\x7cPkiMiXIUN~,;?%*\-/; }

 elsif ($input_type eq "unihtml") {
   my %unihtml2roman = (
 '&#1575;' => 'A', '&#9791;' => '|', "&#1576;" => 'b', '&#1577;' => 'P', '&#1662;' => 'p', '&#1578;' => 't', '&#1579;' => 'V', '&#1580;' => 'j', '&#1670;' => 'c', '&#1581;' => 'H', '&#1582;' => 'x', '&#1583;' => 'd', '&#1584;' => 'L', '&#1585;' => 'r', '&#1586;' => 'z', '&#1688;' => 'J', '&#1587;' => 's', '&#1588;' => 'C', '&#1589;' => 'S', '&#1590;' => 'D', '&#1591;' => 'T', '&#1592;' => 'Z', '&#1593;' => 'E', '&#1594;' => 'G', '&#1601;' => 'f', '&#1602;' => 'q', '&#1603;' => 'k', '&#1705;' => 'k', '&#1711;' => 'g', '&#1604;' => 'l', '&#1605;' => 'm', '&#1606;' => 'n', '&#1608;' => 'u', '&#1607;' => 'h', '&#1610;' => 'i', '&#1740;' => 'i', '&#1609;' => 'A', '&#1614;' => 'a', '&#1615;' => 'o', '&#1616;' => 'e', '&#1617;' => '~', '&#1570;' => ']', '&#1569;' => 'M', '&#1611;' => 'N', '&#1571;' => '|', '&#1572;' => 'U', '&#1573;' => '|', '&#1574;' => 'I', '&#1728;' => 'X', '&#1642;' => '%', '&#1548;' => ',', '&#1563;' => ';', '&#1567;' => '?', '&#8204;' => "-", ' ' => ' ', '.' => '.', ':' => ':', );
  my @charx = split(/(?=\&\#)|(?=\s)|(?=\n)/, $_);
  $_ = "";
  foreach my $charx (@charx)
  {
    my $text_from_new = $unihtml2roman{$charx};
    $_ = $_ . $text_from_new;
  } # Ends foreach
 }  # Ends elsif ($input_type eq "unihtml")

 elsif ($input_type eq "cp1256") {
  $_ =~ tr/\xc7\xc8\x81\xca\xcb\xcc\x8d\xcd\xce\xcf\xd0\xd1\xd2\x8e\xd3\xd4\xd5\xd6\xd8\xd9\xda\xdb\xdd\xde\xdf\x90\xe1\xe3\xe4\xe6\xe5\xed\xf3\xf5\xf6\xc2\xff\xc9\x98\xc1\xc0\xc6\xc4\xf0\xf8\xa1\xba\xbf\xab\xbb\x9d\xec/AbptVjcHxdLrzJsCSDTZEGfqkglmnuhiaoe\x5d\x7cPkMXIUN~,;?{}\-i/; }

 elsif ($input_type eq "isiri3342") {
  $_ =~ tr/\xc1\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xfe\xf0\xf2\xf1\xc0\xc1\xfc\xda\xe1\xc2\xfb\xfa\xf3\xf6\xac\xbb\xbf\xa5\xe7\xe6\xa1/AbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoe\x5d\x7cPkiMIUN~,;?%{}\-/; }

 $_ =~ s/\bA/|/g; # eg. AirAn -> |irAn
} # if ($input_type)


if ( $unvowel ) {
 $_ =~ s/\b([aeo])/|/g; # Inserts alef before words that begin with short vowel
 $_ =~ s/\bA/]/g;       # Changes long 'aa' at beginning of word to alef madda
 $_ =~ s/[aeo~]//g;     # Finally, removes all other short vowels and tashdids
}

if ( $zwnj ) {
#Inserts ZWNJ's where they should have been originally, but weren't
$_ =~ s/(?<![a-zA-Z|])mi /mi-/g;    # 'mi-'
$_ =~ s/(?<![a-zA-Z|])nmi /nmi-/g;  # 'mi-'
$_ =~ s/ hA(?![a-zA-Z|])/-hA/g;     # '-hA'
$_ =~ s/ hAi(?![a-zA-Z|])/-hAi/g;   # '-hA'
$_ =~ s/h \|i(?![a-zA-Z|])/h-\|i/g; # '+h-|i'
}

unless ($dont_stem){ # Do stemming regexes unless $dont_stem is true

if ( $resolve{$_} ) { $_ = $resolve{$_} } # word is found in Resolve section
else {

## If these regular expressions are readable to you, you need to check-in to a psychiatric ward!
## If Perl 6 grammars were available to me upon starting this project, the following would look much nicer


##### Verb Section #####

######## Verb Prefixes ########
$_ =~ s/\b(?<!\]|\|)n(?![uAi])(\S{2,}?(?:im|id|nd|(?<!A)m|(?<![Au])i|(?<!A)d|(?:r|u|i|A|n|m|z)dn|(?:f|C|x|s)tn)(?:mAn|tAn|CAn|C)?)\b/n+_$1/g; # neg. verb prefix 'n+'
$_ =~ s/(\bn\+_|\b(?<!\]|\|))mi-(?![uAi])(\S{2,}?(?:im|id|nd|(?<!A)m|(?<!A)i|(?<!A)d)(?:mAn|tAn|CAn|C)?)\b/$1mi-+_$2/g;    # Durative verb prefix 'mi+'
$_ =~ s/(\bn\+_|\b(?<!\]|\|))mi(?![uAi])(?!-)(\S{2,}?(?:im|id|nd|(?<!A)m|(?<!A)i|(?<!A)d)(?:mAn|tAn|CAn|C)?)\b/$1mi+_$2/g; # Durative verb prefix 'mi+'
$_ =~ s/\b(?<!\]|\|)b(?![uAi])([^ ]{2,}?(?:im|id|nd|(?<!A)m|(?<!A)i|d)(?:mAn|tAn|CAn|C)?)\b/b+_$1/g;       # Subjunctive verb prefix 'be+'

######## Verb Suffixes & Enclitics ########
$_ =~ s/(\S{2,}?(?:[^+ ]{2}d|[^+ ]{2}(?:s|f|C|x)t|\bn\+_\S{2,}?|mi\+_\S{2,}?|b\+_\S{2,}?)(?:im|id|nd|m|(?<!A|u)i|d))(CAn|tAn|C)\b/$1_+$2/g;   # Verbal Object verb enclitic
$_ =~ s/\b(n\+_\S{2,}?|\S?mi\+_\S{2,}?|b\+_\S{2,}?)([uAi])([iI])(im|id|i)(_\+\S*)?\b/$1$2_+0$4$5/g;    # Removes epenthesized 'i/I' before Verbal Person suffixes 'im/id/i'
$_ =~ s/\b(n\+_\S{2,}?|\S?mi\+_\S{2,}?|b\+_\S{2,}?)([uA])i(nd|d|m)(_\+\S*?)?\b/$1$2_+0$3$4/g;    # Removes epenthesized 'i' before Verbal Person suffixes 'm/d/nd'
$_ =~ s/((?>\S*?)(?:\S{3}(?<!A)d|\S(?:s|f|C|x)t|mi-?\+_\S{2,}?|\bn\+_(?!mi)\S{2,}?|\bb\+_\S{2,}?))((?<!A)nd|id|im|d|(?<!A|u)i|m)(_\+\S*?)?\b/$1_+$2$3/g;    # Verbal Person verb suffix
$_ =~ s/(\S{2,}?)(?<!A)d_\+(nd|id|im|d|i|m)(_\+\S*?)?\b/$1_+d_+$2$3/g;    # Verbal tense suffix 'd'
$_ =~ s/(\S+?)(s|f|C|x)t_\+(nd|id|im|d|i|m)(_\+\S*?)?\b/$1$2_+t_+$3$4/g;  # Verbal tense suffix 't'

$_ =~ s/\b(\S{2,}?)(r|u|i|A|n|m)dn\b/$1$2_+dn/g;               # Verbal Infinitive '+dan'
$_ =~ s/\b(\S{2,}?)(f|C|x|s)tn\b/$1$2_+tn/g;                   # Verbal Infinitive '+tan'
$_ =~ s/\b(\S{2,}?)(i|n|A|u|z|r|b|h|s|k|C|f)ndh\b/$1$2_+ndh/g; # Verbal present participle '+andeh'
$_ =~ s/\b(\S{2,}?)(C|r|n|A|u|i|m|z)dh\b/$1$2_+d_+h/g;         # Verbal past participle '+deh'
$_ =~ s/\b(\S{2,}?)(C|f|s|x)th\b/$1$2_+t_+h/g;                 # Verbal past participle '+teh'

$_ =~ s/\b(C|z|kr|bu|dA|ur|di|br|\]m|mr|kn|ci)d(h|n)\b/$1_+d_+$2/g;  # Short +dan verbs, eg. 'shodan/zadan' Infinitive or Verbal past participle
$_ =~ s/\b(rf|gf)t(h|n)\b/$1_+t_+$2/g;  # Short +tan verbs, eg. 'raftan/goftan' Infinitive or Verbal past participle
$_ =~ s/\b(C|z|kr|bu|dA|ur|di|br|\]m|mr|kn|rsi|ci)d(nd|i|id|m|im)?\b/$1_+d_+$2/g;  # 'shodan/zadan...' simple past - temp. until resolve file works
$_ =~ s/\b(rf|gf)t(nd|i|id|m|im)?\b/$1_+t_+$2/g;  # 'raftan/goftan' simple past - temp. until resolve file works
$_ =~ s/\b(xuAh|dAr|kn|Cu|bAC)(d|nd|id|i|im|m)\b/$1_+$2/g;  # future/have - temp. until resolve file works
$_ =~ s/_\+d_\+\B/_+d/g;  # temp. until resolve file works
$_ =~ s/_\+t_\+\B/_+t/g;  # temp. until resolve file works

######## Contractions ########
$_ =~ s/\b([^+ ]+?)([uAi])st(\p{P})/$1$2 |st$3/g; # normal "[uAi] ast", is often followed by punctuation (eg. mAst vs ...mA |st.)


##### Noun Section #####

$_ =~ s/\b([^+ ]{2,}?)(u|A)i(CAn|C|tAn|mAn)(_\+.*?)?\b/$1$2_+0_+$3$4/g;  # Removes epenthesized 'i' before genitive pronominal enclitics
$_ =~ s/\b([^+ ]{2,}?)([^uAi+ ])(CAn|(?<!s)tAn)(_\+.*?)?\b/$1$2_+$3$4/g;     # Genitive pronominal enclitics
#$_ =~ s/\b([^+ ]{2,}?)(A|u)\b//g;            # Removes epenthesized 'i' before accusative enclitics
$_ =~ s/\b([^+ ]{2,}?)(?<!A)gAn\b/$1h_+An/g;  # Nominal plural suffix from stem ending in 'eh'
$_ =~ s/\b([^+ ]+?)(A|u)i\b/$1$2_+e/g;        # Ezafe preceded by long vowel
$_ =~ s/\b([^+ ]{2,}?)(hA|-hA)\b/$1_+$2/g;            # Nominal plural suffix
$_ =~ s/\b([^+ ]{2,}?)(hA|-hA)(_\+\S*?)\b/$1_+$2$3/g; # Nominal plural suffix
$_ =~ s/\b([^+ ]{3,}?)(?<!st)(An)\b/$1_+$2/g;         # Plural suffix '+An'
$_ =~ s/\b(\S*?[$ar_chars]\S*?)At\b/$1h/og;           # Arabic plural: +At
$_ =~ s/\b((?:m|\|)\S*?)At\b/$1h/g;                   # Arabic plural: +At

##### Adjective Section #####

$_ =~ s/\b([^+ ]+?)trin\b/$1_+trin/g;   # Adjectival superlative suffix
$_ =~ s/\b([^+ ]+?)tr\b/$1_+tr/g;       # Adjectival comparative suffix
$_ =~ s/\b([^+ ]+?)(?<!A)gi\b/$1h_+i/g; # Adjectival suffix from stem ending in 'eh'
$_ =~ s/\b([^+ ]+?)(i|I)i\b/$1_+i/g;    # '+i' suffix preceded by 'i' (various meanings)
$_ =~ s/([^+ ]+?)e\b/$1_+e/g;           # An ezafe

##### End #####

### Increase recall, but lower precision; also contains experimental regexes
if ( $recall ) {
 $_ =~ s/\b([^+ ]{3,}?)(?<![Au])i\b/$1_+i/g;         # Indef. '+i' suffix
 $_ =~ s/\b([^+ ]*?[$ar_chars][^+ ]*?)t\b/$1_+t/og;  # Arabic fem: +at
 $_ =~ s/\b(m[^+ ]{3,}?)(?<![Aiu])t\b/$1_+t/g;       # Arabic fem: +at
 $_ =~ s/\b([^+ ]{2,}?(?:r|(?<![Ai])u|(?<![Au])i|n|m|z))d(?!\s)\b/$1_+d/g; # 3rd person singular past verb - voiced
 $_ =~ s/\b([^+ ]{2,}?(?:f|C|x|s))t(?!\s)\b/$1_+t/g;       # 3rd person singular past verb - unvoiced
# $_ =~ s/\b(n?)([^+ ]{2,}?)((?<=r|u|i|A|n|m|z)d|(?<=f|C|x|s)t)(?!\s)\b/$1+_$2_+$3/g; # 3rd person singular past verb & neg.
 $_ =~ s/(\S{2,}?(?:[^+ ]{2}d|[^+ ]{2}(?:s|f|C|x)t|\bn\+_\S{2,}?|mi\+_\S{2,}?|b\+_\S{2,}?)(?:im|id|nd|m|(?<!A|u)i|d))mAn\b/$1_+mAn/g;   # Verbal Object verb enclitic +mAn
 $_ =~ s/\b([^+ ]{2,}?)([^uAi+ ])(mAn|C)(_\+\S*?)?\b/$1$2_+$3$4/g;     # Genitive pronominal enclitics +mAn or +C
}

### Deletes everything but the root
if ( $show_only_root ) {
# $_ =~ s/\b[_+$al]*\+_([_+$al]+?)\b/$1/g;  # Removes prefixes
# $_ =~ s/\b([_+$al]+?)_\+[_+$al]*\b/$1/g;  # Removes suffixes
 $_ =~ s/\b[^ ]+\+_([^ ]+?)\b/$1/g;  # Removes prefixes
 $_ =~ s/\b([^ ]+?)_\+[^ ]+\b/$1/g;  # Removes suffixes
}

} # ends else -- not found in Resolve section
} # ends unless $dont_stem

### Deletes word boundaries ' ' from morpheme links '_+'/'+_'
unless ( $show_links ) {
 $_ =~ s/_\+0/ /g;  # Removes epenthesized letters
 $_ =~ s/_\+-/ /g;  # Removes suffix links w/ ZWNJs
 $_ =~ s/_\+/ /g;   # Removes all suffix links
 $_ =~ s/-\+_/ /g;  # Removes prefix links w/ ZWNJs
 $_ =~ s/\+_/ /g;   # Removes all prefix links
}

### Tokenizes punctuation
if ( $tokenize ) {
 $_ =~ s/([ ,.;:!?(){}#1-9\/])/ $1 /g;  # Pads punctuation w/ spaces
 $_ =~ s/(\s){2,}/$1/g;                 # Removes multiple spaces
 $_ =~ s/== 2 0==/==20==/g;             # Quickie bugfix for newlines
}


### Converts from romanized to native script
if ($output_type) {
 if ($output_type eq "utf8") {
  $_ =~ tr/AbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoe\x5d\x7cPkiMXIUN~,;?%*\-/ابپتثجچحخدذرزژسشصضطظعغفقكگلمنوهيَُِآاةکیءۀئؤًّ،؛؟٪‍‌/; 
#  $_ =~ s/\./‫.‪/g; # Corrects periods to be RTL embedded
  }

 elsif ($output_type eq "unihtml") {
   my %roman2unihtml = (
            'A' => '&#1575;', '|' => '&#1575;', 'b' => '&#1576;', 'p' => '&#1662;', 't' => '&#1578;', 'V' => '&#1579;', 'j' => '&#1580;', 'c' => '&#1670;', 'H' => '&#1581;', 'x' => '&#1582;', 'd' => '&#1583;', 'L' => '&#1584;', 'r' => '&#1585;', 'z' => '&#1586;', 'J' => '&#1688;', 's' => '&#1587;', 'C' => '&#1588;', 'S' => '&#1589;', 'D' => '&#1590;', 'T' => '&#1591;', 'Z' => '&#1592;', 'E' => '&#1593;', 'G' => '&#1594;', 'f' => '&#1601;', 'q' => '&#1602;', 'k' => '&#1705;', 'K' => '&#1603;', 'g' => '&#1711;', 'l' => '&#1604;', 'm' => '&#1605;', 'n' => '&#1606;', 'u' => '&#1608;', 'v' => '&#1608;', 'w' => '&#1608;', 'h' => '&#1607;', 'X' => '&#1728;', 'i' => '&#1740;', 'I' => '&#1574;', 'a' => '&#1614;', 'o' => '&#1615;', 'e' => '&#1616;', '~' => '&#1617;', ',' => '&#1548;', ';' => '&#1563;', '?' => '&#1567;', ']' => '&#1570;', 'M' => '&#1569;', 'N' => '&#1611;', 'U' => '&#1572;', '-' => '&#8204;', ' ' => ' ', '_' => '_', '+' => '+', "\n" => '<br/>', '.' => '&#8235.&#8234;', );
  my @charx = split(//, $_);
  $_ = "";
  foreach my $charx (@charx)
  {
    my $newchar = $roman2unihtml{$charx};
    $_ = $_ . $newchar;
  } # Ends foreach
 }  # Ends elsif (unihtml)

 elsif ($output_type eq "cp1256") {
  $_ =~ tr/AbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoe\x5d\x7cPkMXIUN~,;?{}\-i/\xc7\xc8\x81\xca\xcb\xcc\x8d\xcd\xce\xcf\xd0\xd1\xd2\x8e\xd3\xd4\xd5\xd6\xd8\xd9\xda\xdb\xdd\xde\xdf\x90\xe1\xe3\xe4\xe6\xe5\xed\xf3\xf5\xf6\xc2\xff\xc9\x98\xc1\xc0\xc6\xc4\xf0\xf8\xa1\xba\xbf\xab\xbb\x9d\xec/;
#  $_ =~ s/\x2e/\xfe\x2e\xfd/g; # Corrects periods to be RTL embedded; broken
 }

 elsif ($output_type eq "isiri3342") {
  $_ =~ tr/AbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoe\x5d\x7cPkiMIUN~,;?%{}\-/\xc1\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xfe\xf0\xf2\xf1\xc0\xc1\xfc\xda\xe1\xc2\xfb\xfa\xf3\xf6\xac\xbb\xbf\xa5\xe7\xe6\xa1/; }

 elsif ($output_type eq "arabtex") {
   my %roman2arabtex = (
     'A' => 'A', '|' => 'a', 'b' => 'b', 'p' => 'p', 't' => 't', 'V' => '_t', 'j' => 'j', 'c' => '^c', 'H' => '.h', 'x' => 'x', 'd' => 'd', 'L' => '_d', 'r' => 'r', 'z' => 'z', 'J' => '^z', 's' => 's', 'C' => '^s', 'S' => '.s', 'D' => '.d', 'T' => '.t', 'Z' => '.z', 'E' => '`', 'G' => '.g', 'f' => 'f', 'q' => 'q', 'K' => 'k', 'k' => 'k', 'g' => 'g', 'l' => 'l', 'm' => 'm', 'n' => 'n', 'u' => 'U', 'v' => 'w', 'w' => 'w', 'h' => 'h', 'X' => 'H-i', 'i' => 'I', 'I' => '\'y', 'a' => 'a', 'o' => 'o', 'e' => 'e', 'P' => 'T', '~' => '', ',' => ',', ';' => ';', '?' => '?', ']' => '^A', 'M' => '\'', 'N' => 'aN', 'U' => 'U\'', '{' => '\lq ', '}' => '\rq ', '-' => '\hspace{0ex}', '.' => '.', ' ' => ' ', '_' => '_', '+' => '+', );
  my @charx = split(//, $_);
  $_ = "";
  foreach my $charx (@charx)
  {
    my $newchar = $roman2arabtex{$charx};
    $_ = $_ . $newchar;
  } # Ends foreach
#  $_ = $_ . '\\\\'; # Appends LaTeX newline '\\' after each line
 }  # Ends elsif (arabtex)

 if ($output_type eq "utf8" && m/[^ .\n]/) { # If utf8 & non-empty
   binmode(STDOUT, ":utf8"); # Uses the :utf8 output layer 
   s/==20==/\n/g && print "$_" or print "$_ ";
 }
 elsif ( /[^ .\n]/ ) { # if arabic-script line is non-empty
   s/==20==/\n/g && print "$_" or print "$_ ";
 }
} # if ($output_type) -- for non-roman input
elsif ( /[^ .\n]/ ) { # if roman-script line is non-empty 
    s/==20==/\n/g && print "$_" or print "$_ ";
}


} # ends foreach @_
} # ends while (<>)


### Resolve section
## The format of the Resolve section ( __DATA__ ) is as follows:
## 1. Mokassar (broken plurals): 	'ktb	ktAb'    OR    'ktb	ktAb_+PL'
## 2. Preparsed (speed):		'krdn	kr_+dn'
## 3. Don't stem (false positive):	'bArAn	bArAn'
## 4. Stop word (delete):		'u	'
__DATA__
#u	
#dr	
#bh	
#|z	
#kh	
#|in	
#mi	
#rA	
#bA	
#hA	
#]n	
#ik	
#hm	
#mn	
#tu	
#|u	
#mA	
#CmA	
#tA	
#digr	
#iA	
#|mA
#|gr
#hr
#ps
#ch
#iki
#hic
#uli
#nh
#|st
#hA
#bi
#|i
#br
u	u
dr	dr
bh	bh
|z	|z
kh	kh
|in	|in
mi	mi
rA	rA
bA	bA
hA	hA
]n	]n
ik	ik
hm	hm
mn	mn
tu	tu
|u	|u
mA	mA
CmA	CmA
tA	tA
digr	digr
iA	iA
|mA	|mA
|gr	|gr
hr	hr
ps	ps
ch	ch
iki	iki
hic	hic
uli	uli
nh	nh
|st	|st
hA	hA
bi	bi
|i	|i
br	br
|iCAn	|iCAn
]nhA	]nhA
]nAn	]nAn
bArAn	bArAn
thrAn	thrAn
tim	tim
hfth	hfth
kihAn	kihAn
Hti	Hti
zndgi	zndgi
sAzmAn	sAzmAn
EnuAn	EnuAn
nZAm	nZAm
jhAn	jhAn
pAiAn	pAiAn
biCtr	biCtr
miAn	miAn
frhngi	frhngi
tnhA	tnhA
|ntxAbAt	|ntxAbAt
|stfAdh	|stfAdh
iAzdh	iAzdh
duAzdh	duAzdh
pAnzdh	pAnzdh
sizdh	sizdh
CAnzdh	CAnzdh
nuzdh	nuzdh
frxndh	frxndh
]mrikA	]mrikA
rIis	rIis
xndh	xndh
lndn	lndn
mEdn	mEdn
tmdn	tmdn
|rdn	|rdn
grdn	grdn
lAdn	lAdn
kudn	kudn
mAdh	mAdh
jAdh	jAdh
|st	|st
bud	bud
br	br
ktb	ktAb
|fkAr	fkr
|EDA	EDu
|fGAnstAn	|fGAnstAn
mrA	mn rA
trA	tu rA
cist	ch |st
krdn	kr_+dn
Cdh	C_+d_+h
krdh	kr_+d_+h
mrdm	mrd_+m
dAdh	dA_+d_+h
budh	bu_+d_+h
zbAnhAi	zbAn_+hA_+e
zbAnhA	zbAn_+hA
budh	bu_+d_+h
gLCth	gLC_+t_+h
budnd	bud_+nd
dACth	dAC_+t_+h
krdnd	krd_+nd
rui	ru_+e
kCurhAi	kCur_+hA_+e
kCurhA	kCur_+hA
sui	su_+e
grfth	grf_+t_+h
Cdn	C_+dn
]indh	]i_+ndh
dftr	dftr
dfAtr	dfAtr
dktr	dktr
sAxth	sAx_+t_+h
]mdh	]m_+d_+h
rAi	rA_+e
jAi	jA_+e
uqt	uqt
gLACth	gLAC_+t_+h
budn	bu_+dn
didn	di_+dn
didh	di_+d_+h
dAdn	dA_+dn
zdh	z_+d_+h
zdnd	z_+d_+nd
dAdnd	dAd_+nd
|slAmi	|slAm_+i
knnd	kn_+nd
knd	kn_+d
Cud	Cu_+d
dhd	dh_+d
dArd	dAr_+d
xuAhd	xuAh_+d
nist	n+_|st
kjAst	kjA+_|st
]mrikAii	]mrikA_+i
|nsAni	|nsAn_+i
