#!/usr/bin/env perl
# Written by Jon Dehdari 2004-2012
# Perstem:  Stemmer and Morphological Parser for Persian
# The license is the GPL v.3 (www.fsf.org)
# Usage:  perl perstem.pl [options] < input > output

use 5.8.0;
use strict;
#use warnings;
#use diagnostics;
use Getopt::Long;

my $version        = '1.3b3';
my $date           = '2012-07-12';
my $copyright      = '(c) 2004-2012  Jon Dehdari - GPL v3';
my $title          = "Perstem: Persian stemmer $version, $date - $copyright";
my ( $dont_stem, $flush, $no_roman, $pos, $recall, $show_links, $show_only_stem, $skip_comments, $tokenize, $unvowel, $zwnj )  = undef;
my ( $pos_v, $pos_n, $pos_aj, $pos_other, $before_resolve )  = undef;
my $ar_chars       = 'EqHSTDZLVU';
#my $longvowel     = 'Aui]';
my %resolve;

### Defaults
my $pos_sep = '/';
my $input_type  = 'roman';	# default is roman input
my $output_type = 'roman';	# default is roman output

my $usage       = <<"END_OF_USAGE";
${title}

Usage:     perl $0 [options] < input > output

Function:  Persian (Farsi) stemmer, morphological analyzer, transliterator,
           and partial part-of-speech tagger.

Options:
  -d, --nostem           Don't stem -- mostly for character-set conversion
      --flush            Autoflush buffer output after every line
  -h, --help             Print usage
  -i, --input <type>     Input character encoding type {cp1256,isiri3342,utf8,unihtml}
  -l, --links            Show morphological links
  -n, --noroman          Delete all non-Arabic script characters (eg. HTML tags)
  -o, --output <type>    Output character encoding type {arabtex,cp1256,isiri3342,roman,utf8,unihtml}
  -p, --pos              Tag inflected words for parts of speech
      --pos-sep <char>   Separate words from their parts of speech by <char> (default: "$pos_sep" )
  -r, --recall           Increase recall by parsing ambiguous affixes; may lower precision
      --skip-comments    Skip commented-out lines, without printing them
  -s, --stem             Return only word stems
  -t, --tokenize         Tokenize punctuation
  -u, --unvowel          Remove short vowels
  -v, --version          Print version ($version)
  -z, --zwnj             Insert Zero Width Non-Joiners where they should be

END_OF_USAGE
#  -s, --stoplist <file>   Use external stopword list <file>

GetOptions(
  'd|nostem'      => \$dont_stem,
  'flush'         => \$flush,
  'h|help|?'      => sub { print $usage; exit; },
  'i|input:s'     => \$input_type,
  'l|links'       => \$show_links,
  'n|noroman'     => \$no_roman,
  'o|output:s'    => \$output_type,
  'p|pos'	    => \$pos,
  'pos-sep:s'     => \$pos_sep,
  'r|recall'	    => \$recall,
  'skip-comments' => \$skip_comments,
#  's|stoplist:s'  => \$resolve_file,
  's|stem'        => \$show_only_stem,
  't|tokenize'    => \$tokenize,
  'u|unvowel'     => \$unvowel,
  'v|version'     => sub { print "$version\n"; exit; },
  'z|zwnj'        => \$zwnj,
  ) or die $usage;

$input_type  =~ s/.*1256/cp1256/; # equates win1256 with cp1256
$output_type =~ s/.*1256/cp1256/; # equates win1256 with cp1256
$input_type  =~ tr/[A-Z]/[a-z]/;  # recognizes more encoding spelling variants
$output_type =~ tr/[A-Z]/[a-z]/;  # recognizes more encoding spelling variants
$input_type  =~ tr/-//;           # eg. UTF-8 & utf8
$output_type =~ tr/-//;           # eg. UTF-8 & utf8


### Open Resolve section
while (my $resolve = <DATA>) {
  next if $resolve =~ /^#/;
  chomp $resolve;
  my @resolve = split /\t/, $resolve;
  $resolve{"$resolve[0]"} = [$resolve[1], $resolve[2]];
}


### A hack for what Perl should have already done: support at runtime BOTH utf8 & other input/output types
if ($input_type eq 'utf8') { # UTF-8 input
  use encoding "utf8";
  open STDIN, "<:encoding(UTF-8)" ;
}
elsif ($output_type eq 'utf8') { # UTF-8 output
  use encoding "utf8";
  open STDOUT, "<:encoding(UTF-8)" ;
}
else { unimport encoding "utf8";}


### Autoflush buffers, for piping STDOUT
$| = 1  if $flush;


while (<>) {

  my $full_line;

  if ( /^$/ | /^\s+$/ | /^#/ ) {	# Treat empty or commented-out lines
    if ($skip_comments) { next; }	# Don't even print them out
    else { print; next; }		# At least print them out
  }
  tr/\r/\n/d;	# Deletes lame DOS carriage returns
  s/\n/ ====/;	# Converts newlines to temporary placeholder ====

### Tokenizes punctuation
  if ( $tokenize ) {
    s/([,.;:!?(){}«»#\/])/ $1 /g;	# Pads punctuation w/ spaces
    s/(?<!.)(\d+)/ $1 /g;		# Pads numbers w/ spaces
    s/(\s){2,}/$1/g;			# Removes multiple spaces
  }

### Converts from native script to romanized transliteration
  if ($input_type ne 'roman') {
    if ($output_type eq 'roman') {
      ## Surround contiguous Latin-script blocks with pseudo-quotes
      s/([a-zA-Z01-9\x5d\x7c~,;?%*\-]+)/˹${1}˺/g;
    }

    ## Preserve Latin characters by temporarily mapping them to their circled unicode counterparts, or other doppelgaenger chars
    ## \x5d == "]"  \x7c == "|"
    tr/a-zA-Z01-9\x5d\x7c~,;?%*\-]+/ⓐ-ⓩⒶ-Ⓩ⓿①-⑨⁆‖⁓‚;⁇‰⁎‐⌉✢/;

    if ($no_roman) {
      s/<br>/\n/g;
      s/<p>/\n/g;
      tr/\x01-\x09\x1b-\x1f\x21-\x2d\x2f-\x5a\x5c\x5e-\x9f//d; # Deletes all chars below xa0 except: 0a,20,2e,5b,5d
    }

    if ($input_type eq 'utf8') {
      tr/اأبپتثجچحخدذرزژسشصضطظعغفقكگلمنوهيَُِآ☿ةکیءىۀئؤًّ،؛؟٪‍‌/ABbptVjcHxdLrzJsCSDTZEGfqkglmnuhiaoe\x5d\x7cPkiMiXIUN~,;?%*\-/;
    }

    elsif ($input_type eq 'unihtml') {
      my %unihtml2roman = (
        '&#1575;' => 'A', '&#9791;' => 'A', '&#1571;' => 'B', '&#1576;' => 'b', '&#1577;' => 'P', '&#1662;' => 'p', '&#1578;' => 't', '&#1579;' => 'V', '&#1580;' => 'j', '&#1670;' => 'c', '&#1581;' => 'H', '&#1582;' => 'x', '&#1583;' => 'd', '&#1584;' => 'L', '&#1585;' => 'r', '&#1586;' => 'z', '&#1688;' => 'J', '&#1587;' => 's', '&#1588;' => 'C', '&#1589;' => 'S', '&#1590;' => 'D', '&#1591;' => 'T', '&#1592;' => 'Z', '&#1593;' => 'E', '&#1594;' => 'G', '&#1601;' => 'f', '&#1602;' => 'q', '&#1603;' => 'k', '&#1705;' => 'k', '&#1711;' => 'g', '&#1604;' => 'l', '&#1605;' => 'm', '&#1606;' => 'n', '&#1608;' => 'u', '&#1607;' => 'h', '&#1610;' => 'i', '&#1740;' => 'i', '&#1609;' => 'A', '&#1614;' => 'a', '&#1615;' => 'o', '&#1616;' => 'e', '&#1617;' => '~', '&#1570;' => ']', '&#1569;' => 'M', '&#1611;' => 'N', '&#1571;' => 'A', '&#1572;' => 'U', '&#1573;' => 'A', '&#1574;' => 'I', '&#1728;' => 'X', '&#1642;' => '%', '&#1548;' => ',', '&#1563;' => ';', '&#1567;' => '?', '&#8204;' => "-", ' ' => ' ', '.' => '.', ':' => ':', );
      my @charx = split(/(?=\&\#)|(?=\s)|(?=\n)/, $_);
      $_ = "";
      foreach my $charx (@charx) {
        $_ .= $unihtml2roman{$charx};
      }
    }  # ends elsif ($input_type eq 'unihtml')

    elsif ($input_type eq 'cp1256') {
      tr/\xc7\xc3\xc8\x81\xca\xcb\xcc\x8d\xcd\xce\xcf\xd0\xd1\xd2\x8e\xd3\xd4\xd5\xd6\xd8\xd9\xda\xdb\xdd\xde\xdf\x90\xe1\xe3\xe4\xe6\xe5\xed\xf3\xf5\xf6\xc2\xff\xc9\x98\xc1\xc0\xc6\xc4\xf0\xf8\xa1\xba\xbf\xab\xbb\x9d\xec/ABbptVjcHxdLrzJsCSDTZEGfqkglmnuhiaoe\x5d\x7cPkMXIUN~,;?{}\-i/; }

    elsif ($input_type eq 'isiri3342') {
      tr/\xc1\xf8\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xfe\xf0\xf2\xf1\xc0\xc1\xfc\xda\xe1\xc2\xfb\xfa\xf3\xf6\xac\xbb\xbf\xa5\xe7\xe6\xa1/ABbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoe\x5d\x7cPkiMIUN~,;?%{}\-/; }

    #s/\bA/|/g; # eg. AirAn -> |irAn
    #s/˹\|/˹A/g;
  } # if ($input_type)

  @_ = split(/(?<!mi)\s+(?!hA)/); # Tokenize
  foreach (@_) { # Work with each word

    if ( m/^====$/ ) { # no need to do much if it's a newline character
      $full_line .= "\n";
      next;
    }
    elsif ( m/mi ====$/ ) { # Special case if line ends with "mi"
      s/mi ====$/mi\n/g;
    }

    if ( $unvowel ) {
      s/\b([aeo])/A/g; # Inserts alef before words that begin with short vowel
      s/\bA/]/g;       # Changes long 'aa' at beginning of word to alef madda
      s/[aeo~]//g;     # Finally, removes all other short vowels and tashdids
    }

    #Inserts ZWNJ's where they should have been originally, but weren't
    if ( $zwnj ) {
      s/(?<![a-zA-Z])mi /mi-/g;			# 'mi-'
      s/(?<![a-zA-Z])nmi /nmi-/g;			# 'nmi-'
      s/(?<![a-zA-Z])nmi(\S{6,})/nmi-$1/g;	# 'nmi-'
      s/ hA(?![a-zA-Z])/-hA/g;			# '-hA'
      s/ hAi(?![a-zA-Z])/-hAi/g;			# '-hAi'
      s/(\S{6,})hAi(?![a-zA-Z])/$1-hAi/g;	# '-hAi'
      s/h Ai(?![a-zA-Z])/h-Ai/g;			# '+h-Ai'
    }

    unless ($dont_stem){ # Do stemming regexes unless $dont_stem is true

      ( $pos_v, $pos_n, $pos_aj, $pos_other)  = undef;

      if ( $resolve{$_} ) { # word is found in Resolve section
        if    ($resolve{$_}[1] eq 'V') { $pos_v  = 1; }
        elsif ($resolve{$_}[1] eq 'N') { $pos_n  = 1; }
        elsif ($resolve{$_}[1] eq 'A') { $pos_aj = 1; }
        elsif ($resolve{$_}[1] ) { $pos_other = 1; }

        $before_resolve = $_;	# we'll need the original string for POS assignment later
        $_ = $resolve{$_}[0];
      }
      else {

## If these regular expressions are readable to you, you need to check-in to a psychiatric ward!
## If Perl 6 grammars were available to me upon starting this project, the following would look much nicer

##### Verb Section #####

######## Verb Prefixes ########
        s/\b(?<!\])n(?![uAi])(\S{2,}?(?:im|id|nd|(?<!A)m|(?<![Au])i|(?<!A)d|(?:r|u|i|A|n|m|z)dn|(?:f|C|x|s)tn)(?:mAn|tAn|CAn|C)?)\b/n+_$1/g; # neg. verb prefix 'n+'
        s/(\bn\+_|\b(?<!\]))mi-(?![uAi])(\S{2,}?(?:im|id|nd|(?<!A)m|(?<!A)i|(?<!A)d)(?:mAn|tAn|CAn|C)?)\b/$1mi-+_$2/g;    # Imperfective/durative verb prefix 'mi+'
        s/(\bn\+_|\b(?<!\]))mi(?![uAi])(?!-)(\S{2,}?(?:im|id|nd|(?<!A)m|(?<!A)i|(?<!A)d)(?:mAn|tAn|CAn|C)?)\b/$1mi+_$2/g; # Imperfective/durative verb prefix 'mi+'
        s/\b(?<!\])b(?![uAir])([^ ]{2,}?(?:im|id|nd|(?<!A)m|(?<!A)i|d)(?:mAn|tAn|CAn|C)?)\b/b+_$1/g;       # Subjunctive verb prefix 'be+'

######## Verb Suffixes & Enclitics ########
        s/(\S{2,}?(?:[^+ ]{2}d|[^+ ]{2}(?:s|f|C|x)t|\bn\+_\S{2,}?|mi\+_\S{2,}?|b\+_\S{2,}?)(?:im|id|nd|m|(?<!A|u)i|d))(CAn|tAn|C)\b/$1_+$2/g;   # Verbal Object verb enclitic
        s/\b(n\+_\S{2,}?|\S?mi\+_\S{2,}?|b\+_\S{2,}?)([uAi])([iI])(im|id|i)(_\+\S+?)?\b/$1$2_+0$4$5/g;    # Removes epenthesized 'i/I' before Verbal Person suffixes 'im/id/i'

        #s/\b(n\+_\S{2,}?|\S?mi-?\+_\S{2,}?|b\+_\S{2,}?)([uA])i(nd|d|m)(_\+\S+?)?\b/$1$2_+0$3$4/g;    # Removes epenthesized 'i' before Verbal Person suffixes 'm/d/nd'
        s/\b(n\+_\S{2,}?|\S?mi-?\+_\S{2,}?|b\+_\S{2,}?)([uA])i(nd|d|m)(_\+\S+?)?$/$1$2_+0$3$4/g;    # Removes epenthesized 'i' before Verbal Person suffixes 'm/d/nd'
        s/((?>\S*?)(?:\S{3}(?<!A)d|\S(?:s|f|C|x)t|mi-?\+_\S{2,}?|\bn\+_(?!mi)\S{2,}?|\bb\+_\S{2,}?))((?<!A)nd|id|im|d|(?<!A|u)i|m)(_\+\S*?)?\b/$1_+$2$3/g;    # Verbal Person verb suffix
        s/(\S{2,}?)(?<!A)d_\+(nd|id|im|d|m)(_\+\S*?)?\b/$1_+d_+$2$3/g;    # Verbal tense suffix 'd' (sans ..._+d_+i  -- see recall section)
        s/(\S+?)(s|f|C|x)t_\+(nd|id|im|d|i|m)(_\+\S*?)?\b/$1$2_+t_+$3$4/g;  # Verbal tense suffix 't'

        s/\b(\S{2,}?)(r|u|i|A|n|m)dn\b/$1$2_+dn/g;               # Verbal Infinitive '+dan'
        s/\b(\S{2,}?)(f|C|x|s)tn\b/$1$2_+dn/g;                   # Verbal Infinitive '+tan'
        s/\b(\S{2,}?)(i|n|A|u|z|r|b|h|s|k|C|f)ndh\b/$1$2_+ndh/g; # Verbal present participle '+andeh'
        s/\b(\S{2,}?)(C|r|n|A|u|i|m|z)dh\b/$1$2_+dh/g;         # Verbal past participle '+deh'
        s/\b(\S{2,}?)(C|f|s|x)th\b/$1$2_+dh/g;                 # Verbal past participle '+teh'

        s/\b(C|z|kr|bu|dA|ur|di|br|\]m|mr|kn|ci)d(h|n)\b/$1_+d_+$2/g;  # Short +dan verbs, eg. 'shodan/zadan' Infinitive or Verbal past participle
        s/\b(rf|gf)t(h|n)\b/$1_+t_+$2/g;  # Short +tan verbs, eg. 'raftan/goftan' Infinitive or Verbal past participle
        s/\b(C|z|kr|bu|dA|ur|di|br|\]m|mr|kn|rsi|ci)d(nd|i|id|m|im)?\b/$1_+d_+$2/g;  # 'shodan/zadan...' simple past - temp. until resolve file works
        s/\b(rf|gf)t(nd|i|id|m|im)?\b/$1_+t_+$2/g;  # 'raftan/goftan' simple past - temp. until resolve file works
        s/\b(xuAh|dAr|kn|Cu|bAC)(d|nd|id|i|im|m)\b/$1_+$2/g;  # future/have - temp. until resolve file works
        s/_\+d_\+\B/_+d/g;  # temp. until resolve file works
        s/_\+t_\+\B/_+t/g;  # temp. until resolve file works

        m/(?:_\+|\+_)/ and $pos_v = 1;

######## Contractions ########
        s/\b([^+ ]{2,}?)([uAi])st(\p{P})/$1$2 Ast$3/g; # normal "[uAi] ast", is often followed by punctuation (eg. mAst vs ...mA Ast.)

##### Noun Section #####

        unless ( $pos_v ) {
          s/\b([^+ ]{2,}?)(u|A)i(CAn|C|tAn|mAn)(_\+.*?)?\b/$1$2_+0_+$3$4/g;  # Removes epenthesized 'i' before genitive pronominal enclitics
          s/\b([^+ ]{2,}?)([^uAi+ ])(CAn|(?<!s)tAn)(_\+.*?)?\b/$1$2_+$3$4/g;     # Genitive pronominal enclitics

          #s/\b([^+ ]{2,}?)(A|u)\b//g;            # Removes epenthesized 'i' before accusative enclitics
          s/\b([^+ ]{2,}?)(?<!A)gAn\b/$1h_+An/g;  # Nominal plural suffix from stem ending in 'eh'
          s/\b([^+ ]+?)(A|u)i\b/$1$2_+e/g;        # Ezafe preceded by long vowel
          s/\b([^+ ]{2,}?)(hA|-hA)\b/$1_+$2/g;            # Nominal plural suffix
          s/\b([^+ ]{2,}?)(hA|-hA)(_\+\S*?)\b/$1_+$2$3/g; # Nominal plural suffix
          s/\b([^+ ]{4,}?)(?<!st)(An)\b/$1_+$2/g;         # Plural suffix '+An'
          s/\b(\S*?[$ar_chars]\S*?)At\b/$1h_+At/og;       # Arabic fem plural: +At
          s/\b((?:m|A)\S*?)At\b/$1h_+At/g;                # Arabic fem plural: +At

          m/_\+/ and $pos_n = 1;

        }

##### Adjective Section #####

        unless ( $pos_v || $pos_n ) {
          s/\b([^+ ]+?)-?trin\b/$1_+trin/g; # Adjectival superlative suffix, optional ZWNJ
          s/\b([^+ ]+?)-?tr\b/$1_+tr/g;     # Adjectival comparative suffix, optional ZWNJ
          s/\b([^+ ]+?)(?<!A)gi\b/$1h_+i/g; # Adjectival suffix from stem ending in 'eh'
          s/\b([^+ ]+?)(i|I)i\b/$1_+i/g;    # '+i' suffix preceded by 'i' (various meanings)
          s/([^+ ]+?)e\b/$1_+e/g;           # An ezafe

          m/_\+/ and $pos_aj = 1;
        }

##### End #####

### Increase recall, but lower precision; also contains experimental regexes
        if ( $recall ) {
### Verbal ###
          s/(\S{2,}?)(?<!A)d_\+i(_\+\S+?)?\b/$1_+d_+i$3/g; # Verbal tense suffix 'd' + 2nd person singular 'i'
          s/\b([^+ ]{2,}?(?:r|(?<![Ai])u|(?<![Au])i|n|m|z))d(?!\s)\b/$1_+d/g; # 3rd person singular past verb - voiced
          s/\b([^+ ]{2,}?(?:f|C|x|s))t(?!\s)\b/$1_+t/g;       # 3rd person singular past verb - unvoiced

          # s/\b(n?)([^+ ]{2,}?)((?<=r|u|i|A|n|m|z)d|(?<=f|C|x|s)t)(?!\s)\b/$1+_$2_+$3/g; # 3rd person singular past verb & neg.
          s/(\S{2,}?(?:[^+ ]{2}d|[^+ ]{2}(?:s|f|C|x)t|\bn\+_\S{2,}?|mi\+_\S{2,}?|b\+_\S{2,}?)(?:im|id|nd|m|(?<!A|u)i|d))mAn\b/$1_+mAn/g;   # Verbal Object verb enclitic +mAn
          s/\b([^+ ]{3,}?)([uAi])st\b/$1$2 Ast/g; # Less restrictive version of above, eg. mAst -> mA Ast, but sentence-final punctuation not necessary

### Non-verbal ###
          s/\b([^+ ]{3,}?)(?<![Au])i\b/$1_+i/g;        # Indef. '+i' suffix.  This is a very common, but very error-prone suffix.
          s/\b([^+ ]*?[$ar_chars][^+ ]*?)t\b/$1_+t/og; # Arabic fem: +at
          s/\b(m[^+ ]{3,}?)(?<![Aiu])t\b/$1_+t/g;      # Arabic fem: +at
          s/\b([^+ ]{3,}?)At\b/$1h_+At/g;              # Arabic fem plural: +At
          s/\b([^+ ]{2,}?)([^uAi+ ])(mAn|C)(_\+\S*?)?\b/$1$2_+$3$4/g;     # Genitive pronominal enclitics +mAn or +C
          s/\b([^+ ]{2,}?)AN\b/$1_+AN/g;               # Arabic adverbial suffix (fathatan)
        }

      } # ends else -- not found in Resolve section

### Deletes everything but the stem
      if ( $show_only_stem ) {
        s/\b[^ ]+\+_([^ ]+?)\b/$1/g;  # Removes prefixes
        s/\b([^ ]+?)_\+[^ ]+\b/$1/g;  # Removes suffixes
      }

    } # ends unless $dont_stem

### Show parts of speech
    if ( $pos ) {
## Verbal ##
      if ( $pos_v ) {
        s/^(\P{Po}*)(.*?)$/$1${pos_sep}V/;
        my $punct = $2;
        m/b\+_/g            and $_ .= '+SBJN-IMP'; # Subjunctive/imperative 'be'
        m/n\+_/g            and $_ .= '+NEG';      # Negative 'na'
        m/mi-?\+_/g         and $_ .= '+IPFV';     # Imperfective/durative 'mi'
        m/_\+[dt](?!_\+h)/g and $_ .= '+PST';      # Past tense 'd/t'
        m/_\+m/g            and $_ .= '+1.SG';     # 1 person singular 'am'
        m/_\+im/g           and $_ .= '+1.PL';     # 1 person plural 'im'
        m/_\+id/g           and $_ .= '+2.PL';     # 2 person plural 'id'
        m/_\+nd/g           and $_ .= '+3.PL';     # 3 person plural 'nd'
        m/_\+mAn/g          and $_ .= '+1.PL.ACC'; # 1 person plural accusative 'emAn'
        m/_\+tAn/g          and $_ .= '+2.PL.ACC'; # 2 person plural accusative 'etAn'
        m/_\+CAn/g          and $_ .= '+3.PL.ACC'; # 3 person plural accusative 'eshAn'

        m/_\+[dt]n/g    and $_ .= '+INF';  # Infinitive 'dan/tan'
        m/_\+ndh/g      and $_ .= '+PRPT'; # Present participle 'andeh'
        m/_\+[dt]_\+h/g and $_ .= '+PSPT'; # Past participle 'deh/teh'
        $_ .= "$punct";
      }

## Nominal ##
      if ( $pos_n ) {
        s/^(\P{Po}*)(.*?)$/$1${pos_sep}N/;
        my $punct = $2;
        m/_\+-?hA/g and $_ .= '+PL';      # Plural 'hA'
        m/_\+An/g   and $_ .= '+PL.ANIM'; # Plural 'An'
        m/_\+At/g   and $_ .= '+PL';      # Plural 'At'
        m/_\+e/g    and $_ .= '+EZ';      # Ezafe 'e'
        m/_\+C/g    and $_ .= '+3.SG.PC'; # 3 person singular pronominal clitic 'esh'
        m/_\+mAn/g  and $_ .= '+1.PL.PC'; # 1 person plural pronominal clitic 'emAn'
        m/_\+tAn/g  and $_ .= '+2.PL.PC'; # 2 person plural pronominal clitic 'etAn'
        m/_\+CAn/g  and $_ .= '+3.PL.PC'; # 3 person plural pronominal clitic 'eshAn'
        $_ .= "$punct";
      }

## Adjectival ##
      if ( $pos_aj ) {
        s/^(\P{Po}*)(.*?)$/$1${pos_sep}AJ/;
        my $punct = $2;
        m/_\+tr/g   and $_ .= '+CMPR'; # Comparative 'tar'
        m/_\+trin/g and $_ .= '+SUPR'; # Superlative 'tarin'
        $_ .= "$punct";
      }

## Other parts-of-speech
      if ( $pos_other ) {
        s/^(\P{Po}*)(.*?)$/$1$pos_sep$resolve{$before_resolve}[1]/;
        my $punct = $2;
        $_ .= "$punct";
      }
    } # ends if $pos

### Deletes word boundaries ' ' from morpheme links '_+'/'+_'
    unless ( $show_links ) {
      s/_\+0/ /g;  # Removes epenthesized letters
      s/_\+-/ /g;  # Removes suffix links w/ ZWNJs
      s/_\+/ /g;   # Removes all suffix links
      s/-\+_/ /g;  # Removes prefix links w/ ZWNJs
      s/\+_/ /g;   # Removes all prefix links
    }

### Converts from romanized transliteration to native script
    if ($output_type ne 'roman') {
      if ($output_type eq 'utf8') {
        tr/ABbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoe\x5d\x7cPkiMXIUN~,;?%*\-/اأبپتثجچحخدذرزژسشصضطظعغفقكگلمنوهيَُِآاةکیءۀئؤًّ،؛؟٪‍‌/;
      }

      elsif ($output_type eq 'unihtml') {
        my %roman2unihtml = (
          'A' => '&#1575;', '|' => '&#1575;', 'B' => '&#1571;', 'b' => '&#1576;', 'p' => '&#1662;', 't' => '&#1578;', 'V' => '&#1579;', 'j' => '&#1580;', 'c' => '&#1670;', 'H' => '&#1581;', 'x' => '&#1582;', 'd' => '&#1583;', 'L' => '&#1584;', 'r' => '&#1585;', 'z' => '&#1586;', 'J' => '&#1688;', 's' => '&#1587;', 'C' => '&#1588;', 'S' => '&#1589;', 'D' => '&#1590;', 'T' => '&#1591;', 'Z' => '&#1592;', 'E' => '&#1593;', 'G' => '&#1594;', 'f' => '&#1601;', 'q' => '&#1602;', 'k' => '&#1705;', 'K' => '&#1603;', 'g' => '&#1711;', 'l' => '&#1604;', 'm' => '&#1605;', 'n' => '&#1606;', 'u' => '&#1608;', 'v' => '&#1608;', 'w' => '&#1608;', 'h' => '&#1607;', 'X' => '&#1728;', 'i' => '&#1740;', 'I' => '&#1574;', 'a' => '&#1614;', 'o' => '&#1615;', 'e' => '&#1616;', '~' => '&#1617;', ',' => '&#1548;', ';' => '&#1563;', '?' => '&#1567;', ']' => '&#1570;', 'M' => '&#1569;', 'N' => '&#1611;', 'U' => '&#1572;', '-' => '&#8204;', ' ' => ' ', '_' => '_', '+' => '+', "\n" => '<br/>', '.' => '&#8235.&#8234;', );
        my @charx = split(//, $_);
        $_ = '';
        foreach my $charx (@charx) {
          $_ .= $roman2unihtml{$charx};
        }
      }  # ends elsif (unihtml)

      elsif ($output_type eq 'cp1256') {
        tr/ABbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoe\x5d\x7cPkMXIUN~,;?{}\-i/\xc7\xc3\xc8\x81\xca\xcb\xcc\x8d\xcd\xce\xcf\xd0\xd1\xd2\x8e\xd3\xd4\xd5\xd6\xd8\xd9\xda\xdb\xdd\xde\xdf\x90\xe1\xe3\xe4\xe6\xe5\xed\xf3\xf5\xf6\xc2\xff\xc9\x98\xc1\xc0\xc6\xc4\xf0\xf8\xa1\xba\xbf\xab\xbb\x9d\xec/;

        #  s/\x2e/\xfe\x2e\xfd/g; # Corrects periods to be RTL embedded; broken
      }

      elsif ($output_type eq 'isiri3342') {
        tr/ABbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoe\x5d\x7cPkiMIUN~,;?%{}\-/\xc1\xf8\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xfe\xf0\xf2\xf1\xc0\xc1\xfc\xda\xe1\xc2\xfb\xfa\xf3\xf6\xac\xbb\xbf\xa5\xe7\xe6\xa1/; }

      elsif ($output_type eq 'arabtex') {
        my %roman2arabtex = (
          'A' => 'A', '|' => 'a', 'b' => 'b', 'p' => 'p', 't' => 't', 'V' => '_t', 'j' => 'j', 'c' => '^c', 'H' => '.h', 'x' => 'x', 'd' => 'd', 'L' => '_d', 'r' => 'r', 'z' => 'z', 'J' => '^z', 's' => 's', 'C' => '^s', 'S' => '.s', 'D' => '.d', 'T' => '.t', 'Z' => '.z', 'E' => '`', 'G' => '.g', 'f' => 'f', 'q' => 'q', 'K' => 'k', 'k' => 'k', 'g' => 'g', 'l' => 'l', 'm' => 'm', 'n' => 'n', 'u' => 'U', 'v' => 'w', 'w' => 'w', 'h' => 'h', 'X' => 'H-i', 'i' => 'I', 'I' => '\'y', 'a' => 'a', 'o' => 'o', 'e' => 'e', 'P' => 'T', '~' => '', ',' => ',', ';' => ';', '?' => '?', ']' => '^A', 'M' => '\'', 'N' => 'aN', 'U' => 'U\'', '{' => '\lq ', '}' => '\rq ', '-' => '\hspace{0ex}', '.' => '.', ' ' => ' ', '_' => '_', '+' => '+', );
        my @charx = split(//, $_);
        $_ = '';
        foreach my $charx (@charx) {
          $_ .= $roman2arabtex{$charx};
        }

        #  $_ .= '\\\\'; # Appends LaTeX newline '\\' after each line
      }  # ends elsif (arabtex)

      ## Restore temporary Latin doppelgaenger characters to their normal forms
      ## \x5d == "]"  \x7c == "|"
      tr/ⓐ-ⓩⒶ-Ⓩ⓿①-⑨⁆‖⁓‚;⁇‰⁎‐⌉✢/a-zA-Z01-9\x5d\x7c~,;?%*\-]+/;

      if ($output_type eq 'utf8' && m/[^ \n]/) { # If utf8 & non-empty
        binmode(STDOUT, ":utf8"); # Uses the :utf8 output layer
        $full_line .= "$_ ";
      }
      elsif ( /[^ \n]/ ) { # if arabic-script line is non-empty
        $full_line .= "$_ ";
      }

    } # ends if ($output_type ne 'roman') -- for non-roman input
    elsif ( /[^ \n]/ ) { # if latin-script line is non-empty
      if ($input_type ne 'roman') {
        ## Deal with latin-script strings from arabic-script input
        tr/ⓐ-ⓩⒶ-Ⓩ⓿①-⑨⁆‖⁓‚;⁇‰⁎‐⌉✢/a-zA-Z01-9\x5d\x7c~,;?%*\-]+/;
      }
      $full_line .= "$_ ";
    }

  } # ends foreach @_

  $full_line =~ s/ $//;
  print $full_line;

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
#Az	
#kh	
#Ain	
#mi	
#rA	
#bA	
#hA	
#]n	
#ik	
#hm	
#mn	
#tu	
#Au	
#mA	
#CmA	
#tA	
#digr	
#iA	
#AmA	
#Agr	
#hr	
#ps	
#ch	
#iki	
#hic	
#uli	
#nh	
#Ast	
#hA	
#bi	
#Ai	
#br	
u	u	CONJ
iA	iA	CONJ
AmA	AmA	CONJ
uli	uli	CONJ
dr	dr	P
bh	bh	P
Az	Az	P
bA	bA	P
tA	tA	P
bi	bi	P
br	br	P
br	br	P
rui	ru_+e	P+EZ
Hti	Hti	P
sui	su_+e	P+EZ
kh	kh	C
Ain	Ain	DT+PROX
]n	]n	DT+DIST
ik	ik	DT
hr	hr	DT
rA	rA	ACC
rAi	rA_+e	ACC+EZ
mi	mi	MORPH.IPFV
hA	hA	MORPH.PL
Ai	Ai	MORPH
hm	hm
mn	mn	PRON+1.SG
tu	tu	PRON+2.SG
Au	Au	PRON+3.SG
mA	mA	PRON+1.PL
CmA	CmA	PRON+2
AiCAn	AiCAn	PRON+3.PL
]nhA	]nhA	PRON+3.PL
]nAn	]nAn	PRON+3.PL
iki	iki	PRON+3.SG
Agr	Agr	PRT+COND
ps	ps	INTJ
ch	ch
hic	hic	NEG
nh	nh	NEG
bArAn	bArAn	N
tim	tim	N
hfth	hfth	N
kihAn	kihAn	N
zndgi	zndgi	N
sAzmAn	sAzmAn	N
EnuAn	EnuAn	N
nZAm	nZAm	N
jhAn	jhAn	N
pAiAn	pAiAn	N
miAn	miAn	N
frmAndh	frmAndh	N
nmAindh	nmAindh N
prundh	prundh	N
xndh	xndh	N
frxndh	frxndh	A
biCtr	biCtr	A
digr	digr	A
]indh	]i_+ndh	A+PRPT
frhngi	frhngi
tnhA	tnhA
AntxAbAt	AntxAbAt	N
AstfAdh	AstfAdh	N
iAzdh	iAzdh	NUM
duAzdh	duAzdh	NUM
pAnzdh	pAnzdh	NUM
sizdh	sizdh	NUM
CAnzdh	CAnzdh	NUM
nuzdh	nuzdh	NUM
miliArd	miliArd	NUM
rIis	rIis	N
lndn	lndn	N
mEdn	mEdn	N
tmdn	tmdn
grdn	grdn	N
lAdn	lAdn
kudn	kudn
mAdh	mAdh
kilumtr	kilumtr	N
jAdh	jAdh
ktb	ktAb	N
AfkAr	fkr	N
AEDA	EDu
AfGAnstAn	AfGAnstAn	N
AslAmi	AslAm_+i	N
Ardn	Ardn	N
]mrikA	]mrikA	N
]mrikAii	]mrikA_+i
AnsAni	AnsAn_+i	N
thrAn	thrAn	N
pArlmAn	pArlmAn	N
zbAnhAi	zbAn_+hA_+e	N+PL+EZ
zbAnhA	zbAn_+hA	N+PL
kCurhAi	kCur_+hA_+e	N+PL+EZ
kCurhA	kCur_+hA	N+PL
mrdm	mrd_+m	N
dftr	dftr	N
dfAtr	dftr	N
dktr	dktr	N
jAi	jA_+e	N+EZ
uqt	uqt	N
mrA	mn rA
trA	tu rA
cist	ch Ast
kjAst	kjA Ast
xuAhd	xuAh_+d	AUX+3.SG
]mdh	]m_+dh	V+PSPT
Ast	Ast	V.3.SG.PRS
bud	bud	V.3.SG.PST
budh	bu_+dh	V+PSPT
budn	bu_+dn	V+INF
budnd	bu_+d_+nd	V+PST+3.PL
Cdh	C_+dh	V+PSPT
Cdn	C_+dn	V+INF
Cud	Cu_+d	V.PRS+3.SG
Cundh	Cu_+ndh	V.PRS+PRPT
dACth	dAC_+dh	V+PSPT
dAdh	dA_+dh	V+PSPT
dAdn	dA_+dn	V+INF
dAdnd	dA_+d_+nd	V+PST+3.PL
dArd	dAr_+d	V.PRS+3.SG
dhd	dh_+d	V.PRS+3.SG
dhndh	dh_+ndh	V.PRS+PRPT
didn	di_+dn	V+INF
didh	di_+dh	V+PSPT
binndh	bin_+ndh	V.PRS+PRPT
gLACth	gLAC_+dh	V+PSPT
gLCth	gLC_+dh	V+PSPT
grfth	grf_+dh	V+PSPT
knnd	kn_+nd	V.PRS+3.PL
knndh	kn_+ndh	V.PRS+PRPT
knd	kn_+d	V.PRS+3.SG
krdn	kr_+dn	V+INF
krdh	kr_+dh	V+PSPT
krdnd	kr_+d_+nd	V	V+PST+3.PL
nCdh	n+_C_+dh	V+NEG+PSPT
nist	n+_Ast	V+NEG+3.SG.PRS
sAxth	sAx_+dh	V+PSPT
zdh	z_+dh	V+PSPT
zdnd	z_+d_+nd	V+PST+3.PL
znndh	zn_+ndh	V.PRS+PRPT
