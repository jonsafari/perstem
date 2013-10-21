#!/usr/bin/env perl
# Written by Jon Dehdari 2004-2013
# Perstem:  Stemmer and Morphological Parser for Persian
# The license is the GPL v.3 (www.fsf.org)
# Usage:  perl perstem.pl [options] < input > output

use 5.8.0;
use strict;
#use warnings;
#use diagnostics;
use Getopt::Long;

my $version        = '2.2';
my $date           = '2013-10-21';
my $copyright      = '(c) 2004-2013  Jon Dehdari - GPL v3';
my $title          = "Perstem: Persian stemmer $version, $date - $copyright";
my ( $flush, $use_irreg_stems, $no_roman, $pos, $recall, $show_infinitival_form, $show_only_stem, $skip_comments, $tokenize, $unvowel, $zwnj )  = undef;
my ( $pos_aj, $pos_aux, $pos_n, $pos_v, $pos_other, $before_resolve )  = undef;
my (%resolve, %irreg_stems) = undef;
my $ar_chars       = 'BEqHSTDZLVU';
#my $longvowel     = 'AuiO';
### Temporary placement here
my $irreg_stems = "O\tOm\nOmuz\tOmux\nAndAz\tAndAx\nAst\tbu\nbA\tbAis\nbnd\tbs\nbAC\tbu\npz\tpx\npLir\tpLirf\nprdAz\tprdAx\npiund\tpius\ntuAn\ttuAns\nju\tjs\nxuAh\txuAs\ndh\tdA\ndAr\tdAC\ndAn\tdAns\nbin\tdi\nru\trf\nzn\tz\nsAz\tsAx\nspAr\tspr\nCA\tCAis\nCu\tC\nCkn\tCks\nCmAr\tCmr\nCnAs\tCnAx\nCnu\tCni\nfruC\tfrux\nfCAr\tfCr\nkn\tkr\ngLAr\tgLAC\ngLr\tgLC\ngir\tgrf\ngrd\tgC\ngu\tgf\nmir\tmr\nnmA\tnmu\nnuis\tnuC\nhs\tbu\niAb\tiAf\n";
## The "+idan and +Adan" verbs are regular going from past to present, but not the other way around (which is what we must do)
my $semi_reg_stems = "Aft\tAftA\nAist\tAistA\nfrst\tfrstA\nbxC\tbxCi\nprs\tprsi\npic\tpici\ntrs\ttrsi\ncrx\tcrxi\nxr\txri\nrs\trsi\nfhm\tfhmi\nkC\tkCi\nkuC\tkuCi\n";

### Defaults
my $form = 'dict';
my $pos_sep = '/';
my $input_type   = 'utf8'; # default input  is UTF-8
my $output_type  = 'utf8'; # default output is UTF-8
$tokenize        = 1;
$use_irreg_stems = 1;
$zwnj            = 1;

my $usage       = <<"END_OF_USAGE";
${title}

Usage:     perl $0 [options] < input > output

Function:  Persian (Farsi) stemmer, morphological analyzer, transliterator,
           and partial part-of-speech tagger.

Options:
 -f, --form <x>         Output forms as one of the following:
                          dict: as they appear in a dictionary (default)
                          linked: show all morphemes, linked together
                          unlinked: show all morphemes as separate tokens
                          untouched: don't stem/analyze; mostly for char-set conversion
     --flush            Autoflush buffer output after every line
 -h, --help             Print this usage
 -i, --input <type>     Input character encoding type {cp1256,isiri3342,ncr,
                        translit,utf8} (default: $input_type)
     --irreg-stem {0|1} Resolve irregular present-tense verb stems to their
                        past-tense stems (eg. kon -> kar).  (default: 1 == true)
 -n, --noroman          Delete all non-Arabic script characters (eg. HTML tags)
 -o, --output <type>    Output character encoding type {arabtex,cp1256,
                        isiri3342,ncr,translit,utf8} (default: $output_type)
 -p, --pos              Tag inflected words for parts of speech
     --pos-sep <char>   Separate words from their parts of speech by <char>
                        (default: "$pos_sep" )
 -r, --recall           Increase recall by parsing ambiguous affixes; may lower
                        precision
     --skip-comments    Skip commented-out lines, without printing them
 -s, --stem             Return only word stems
 -t, --tokenize {0|1}   Tokenize punctuation (default: 1 == true)
 -u, --unvowel          Remove short vowels
 -v, --version          Print version ($version)
 -z, --zwnj {0|1}       Insert Zero Width Non-Joiners where they should be (default: 1 == true)

END_OF_USAGE
#  -s, --stoplist <file>   Use external stopword list <file>

GetOptions(
  'f|form=s'      => \$form,
  'flush'         => \$flush,
  'h|help|?'      => sub { print $usage; exit; },
  'infinitive'    => \$show_infinitival_form,
  'i|input=s'     => \$input_type,
  'irreg-stem=i'  => \$use_irreg_stems,
  'n|noroman'     => \$no_roman,
  'o|output=s'    => \$output_type,
  'p|pos'         => \$pos,
  'pos-sep:s'     => \$pos_sep,
  'r|recall'      => \$recall,
  'skip-comments' => \$skip_comments,
#  's|stoplist:s'  => \$resolve_file,
  's|stem'        => \$show_only_stem,
  't|tokenize=i'  => \$tokenize,
  'u|unvowel'     => \$unvowel,
  'v|version'     => sub { print "$version\n"; exit; },
  'z|zwnj=i'      => \$zwnj,
  ) or die $usage;

### Postprocess command-line arguments
$input_type  =~ s/.*1256/cp1256/; # equates win1256 with cp1256
$output_type =~ s/.*1256/cp1256/; # equates win1256 with cp1256
$input_type  =~ tr/[A-Z]/[a-z]/;  # recognizes more encoding spelling variants
$output_type =~ tr/[A-Z]/[a-z]/;  # recognizes more encoding spelling variants
$input_type  =~ tr/-//;           # eg. UTF-8 & utf8
$output_type =~ tr/-//;           # eg. UTF-8 & utf8

if ($form eq 'dict') {
  $use_irreg_stems = 1;
  $show_only_stem = 1;
  $show_infinitival_form = 1;
}


### Open Resolve section
while (my $resolve = <DATA>) {
  next if $resolve =~ /^#/;
  chomp $resolve;
  my @resolve = split /\t/, $resolve;
  $resolve{"$resolve[0]"} = [$resolve[1], $resolve[2]];
}

### Open Irregular Verb Stem section
if ($use_irreg_stems) {
  $irreg_stems .= $semi_reg_stems;
  my @lines = split "\n", $irreg_stems;
  foreach (@lines) {
    next if m/^#/;
    chomp;
    my @line = split /\t/, $_;
    $irreg_stems{"$line[0]"} = [ $line[1] ];
  }
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

  if ( /^$/ | /^\s+$/ | /^#/ ) {  # Treat empty or commented-out lines
    if ($skip_comments) { next; } # Don't even print them out
    else { print; next; }         # At least print them out
  }
  tr/\r/\n/d;  # Deletes lame DOS carriage returns
  s/\n/ ====/; # Converts newlines to temporary placeholder ====

### Tokenizes punctuation
  if ( $tokenize ) {
    s/([,.;:!?(){}«»"#\/])/ $1 /g; # Pads punctuation w/ spaces
    s/(?<!.)(\d+)/ $1 /g;          # Pads numbers w/ spaces
    s/(\s){2,}/$1/g;               # Removes multiple spaces
  }

### Converts from native script to dehdari transliteration
  if ($input_type ne 'translit') {
    if ($output_type eq 'translit') {
      ## Surround contiguous Latin-script blocks with pseudo-quotes
      s/([a-zA-Z01-9~,;?%*\-]+)/˹${1}˺/g;
    }

    ## Preserve Latin characters by temporarily mapping them to their circled unicode counterparts, or other doppelgaenger chars
    tr/a-zA-Z01-9~,;?%*\-+/ⓐ-ⓩⒶ-Ⓩ⓿①-⑨⁓‚;⁇‰⁎‐✢/;

    if ($no_roman) {
      s/<br>/\n/g;
      s/<p>/\n/g;
      tr/\x01-\x09\x1b-\x1f\x21-\x2d\x2f-\x5a\x5c\x5e-\x9f//d; # Deletes all chars below xa0 except: 0a,20,2e,5b,5d
    }

    if ($input_type eq 'utf8') {
      tr/اأبپتثجچحخدذرزژسشصضطظعغفقكگلمنوهيَُِآةکیءىۀئؤًّ،؛؟٪‍‌/ABbptVjcHxdLrzJsCSDTZEGfqkglmnuhiaoeOPkiMiXIUN~,;?%*\-/;
    }

    elsif ($input_type eq 'ncr') {
      my %unihtml2roman = (
        '&#1575;' => 'A', '&#9791;' => 'A', '&#1571;' => 'B', '&#1576;' => 'b', '&#1577;' => 'P', '&#1662;' => 'p', '&#1578;' => 't', '&#1579;' => 'V', '&#1580;' => 'j', '&#1670;' => 'c', '&#1581;' => 'H', '&#1582;' => 'x', '&#1583;' => 'd', '&#1584;' => 'L', '&#1585;' => 'r', '&#1586;' => 'z', '&#1688;' => 'J', '&#1587;' => 's', '&#1588;' => 'C', '&#1589;' => 'S', '&#1590;' => 'D', '&#1591;' => 'T', '&#1592;' => 'Z', '&#1593;' => 'E', '&#1594;' => 'G', '&#1601;' => 'f', '&#1602;' => 'q', '&#1603;' => 'k', '&#1705;' => 'k', '&#1711;' => 'g', '&#1604;' => 'l', '&#1605;' => 'm', '&#1606;' => 'n', '&#1608;' => 'u', '&#1607;' => 'h', '&#1610;' => 'i', '&#1740;' => 'i', '&#1609;' => 'A', '&#1614;' => 'a', '&#1615;' => 'o', '&#1616;' => 'e', '&#1617;' => '~', '&#1570;' => 'O', '&#1569;' => 'M', '&#1611;' => 'N', '&#1571;' => 'A', '&#1572;' => 'U', '&#1573;' => 'A', '&#1574;' => 'I', '&#1728;' => 'X', '&#1642;' => '%', '&#1548;' => ',', '&#1563;' => ';', '&#1567;' => '?', '&#8204;' => "-", ' ' => ' ', '.' => '.', ':' => ':', );
      my @charx = split(/(?=\&\#)|(?=\s)|(?=\n)/, $_);
      $_ = "";
      foreach my $charx (@charx) {
        $_ .= $unihtml2roman{$charx};
      }
    }  # ends elsif ($input_type eq 'ncr')

    elsif ($input_type eq 'cp1256') {
      tr/\xc7\xc3\xc8\x81\xca\xcb\xcc\x8d\xcd\xce\xcf\xd0\xd1\xd2\x8e\xd3\xd4\xd5\xd6\xd8\xd9\xda\xdb\xdd\xde\xdf\x90\xe1\xe3\xe4\xe6\xe5\xed\xf3\xf5\xf6\xc2\xc9\x98\xc1\xc0\xc6\xc4\xf0\xf8\xa1\xba\xbf\xab\xbb\x9d\xec/ABbptVjcHxdLrzJsCSDTZEGfqkglmnuhiaoeOPkMXIUN~,;?{}\-i/; }

    elsif ($input_type eq 'isiri3342') {
      tr/\xc1\xf8\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xfe\xf0\xf2\xf1\xc0\xc1\xfc\xda\xe1\xc2\xfb\xfa\xf3\xf6\xac\xbb\xbf\xa5\xe7\xe6\xa1/ABbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoeO\x7cPkiMIUN~,;?%{}\-/; }

    else { die "Perstem error: unrecognized --input type\n\n" . $usage }

  } # if ($input_type)

  @_ = split(/(?<!mi)\s+(?!hA|Ai)/); # Tokenize
  foreach (@_) { # Work with each word

    if ( m/^====$/ ) { # no need to do much if it's a newline character
      $full_line .= "\n";
      next;
    }
    elsif ( m/mi ====$/ ) { # Special case if line ends with "mi"
      s/mi ====$/mi\n/g;
    }

    if ( $unvowel ) {
      s/\bA/O/g;       # Changes long 'aa' at beginning of word to alef madda
      s/\b([aeo])/A/g; # Inserts alef before words that begin with short vowel
      s/[aeo~]//g;     # Finally, removes all other short vowels and tashdids
    }

    #Inserts ZWNJ's where they should have been originally, but weren't
    if ( $zwnj ) {
      s/(?<![a-zA-Z])mi /mi-/g;             # 'mi-'
      s/(?<![a-zA-Z])nmi /nmi-/g;           # 'nmi-'
      s/(?<![a-zA-Z])nmi(\S{6,})/nmi-$1/g;  # 'nmi-'
      s/ hA(?![a-zA-Z])/-hA/g;              # '-hA'
      s/ hAi(?![a-zA-Z])/-hAi/g;            # '-hAi'
      s/(\S{6,})hAi(?![a-zA-Z])/$1-hAi/g;   # '-hAi'
      s/h Ai\b/h-Ai/g;                      # '+h-Ai' (indefinite)
    }

    unless ($form eq 'untouched' ){ # Do full battery of stemming regexes unless told otherwise

      ( $pos_aj, $pos_aux, $pos_n, $pos_v, $pos_other) = undef;

      if ( $resolve{$_} ) { # word is found in Resolve section
        if ($pos or $use_irreg_stems) {
          my $cached_pos_full  = $resolve{$_}[1];
          if ($cached_pos_full) { # Some entries don't have a part-of-speech
            $cached_pos_full =~ m/^([A-Z]+)/  and my $cached_pos_basic = $1;

            if ($cached_pos_basic eq 'A')      { $pos_aj  = 1; }
            elsif ($cached_pos_basic eq 'AUX') { $pos_aux = 1; }
            elsif ($cached_pos_basic eq 'N')   { $pos_n   = 1; }
            elsif ($cached_pos_basic eq 'V')   { $pos_v   = 1; }
            else  {$pos_other = 1;}
          }
        }

        $before_resolve = $_;  # we'll need the original string for POS assignment later
        $_ = $resolve{$_}[0];
      }

      else {

## If these regular expressions are readable to you, you need to check-in to a psychiatric ward!

##### Verb Section #####

######## Verb Prefixes ########
        s/\bn(?![uAi])(\S{2,}?(?:im|id|nd|(?<!A)m|(?<![Aug])i|(?<!A)d|[ruiAnmz]dn|[fCxs]tn)(?:mAn|tAn|CAn|C)?)\b/n+_$1/g; # neg. verb prefix 'n+'
        s/\b(n\+_)?mi-?(?!u|An)(\S{2,}?(?:im|id|nd|(?<!A)m|(?<![Aug])i|(?<!A)d)(?:mAn|tAn|CAn|C)?)\b/$1mi-+_$2/g or  # Imperfective/durative verb prefix 'mi+'
        s/\bb(?![uAr])([^ ]{2,}?(?:im|id|nd|(?<!A)m|(?<![Auig])i|d)(?:mAn|tAn|CAn|C)?)\b/b+_$1/g;       # Subjunctive verb prefix 'be+'
        s/\b(n\+_)?mi-\+_A/$1mi-+_O/g or  # Removes epenthetic yeh following 'mi+' and before alef madda in stem
        s/\bb\+_iA/b+_O/g;                # Removes epenthetic yeh following 'be+' and before alef madda in stem

######## Verb Suffixes & Enclitics ########
        #s/((?:[^+ ]{2}d|[^+ ]{2}[sfCx]t|\bn\+_\S{2,}?|mi\+_\S{2,}?|b\+_\S{2,}?)(?:im|id|nd|m|(?<!A|u)i|d))(CAn|tAn|C)\b/$1_+$2/g;   # Verbal Object verb enclitic
        s/\b(n\+_\S{1,}?|\S?mi-?\+_\S*?|b\+_\S*?)([uAO])([iI])(im|id|i)(_\+\S+?)?\b/$1$2_+$4$5/g or    # Removes epenthetic yeh/yeh-hamza before Verbal Person suffixes 'im/id/i'
        s/\b(n\+_\S{1,}?|\S?mi-?\+_\S*?|b\+_\S*?)([AuO])i(nd|d|m)(_\+\S+?)?$/$1$2_+$3$4/g or    # Removes epenthetic yeh before Verbal Person suffixes 'm/d/nd'
        s/((?>\S*?)(?:\S{3}(?<!A)d|\S[sfCx]t|mi-?\+_\S{2,}?|\bn\+_(?!mi)\S{2,}?|\bb\+_\S{2,}?))((?<!A)nd|id|im|d|(?<![Augd])i|m)(_\+\S*?)?\b/$1_+$2$3/g;    # Verbal Person verb suffix
        s/(\S{2,}?)(?<!A)d_\+(nd|id|im|d|m)(_\+\S*?)?\b/$1_+d_+$2$3/g or    # Verbal tense suffix 'd' (sans ..._+d_+i  -- see recall section);  one exception that breaks on this is mi-dAdnd etc
        s/(\S+?)([sfCx])t_\+(nd|id|im|d|i|m)(_\+\S*?)?\b/$1$2_+t_+$3$4/g or # Verbal tense suffix 't'
        s/(\S{2,}?dA)d_\+(nd|id|im|m)(_\+\S*?)?\b/$1_+d_+$2$3/g;            # Verbal tense suffix 'd' for mi-dAdnd etc.  This class of words are very tricky to get right, without recognizing non-verbs

        s/\b(\S+?)([fCxs])tn(C|CAn|tAn|mAn)\b/$1$2_+dn_+$3/g or   # Gerund (infinitive) '+tan' + pronominal enclitic
        s/\b(\S+?)([ruiAnm])dn(C|CAn|tAn|mAn)\b/$1$2_+dn_+$3/g or # Gerund (infinitive) '+dan' + pronominal enclitic
        s/\b(\S{2,}?)([ruiAnm])dn\b/$1$2_+dn/g or                 # Gerund (infinitive) '+dan'
        s/\b(\S{2,}?)([fCxs])tn\b/$1$2_+tn/g or                   # Gerund (infinitive) '+tan'
        s/\b(\S{2,}?)([inuzrbhskCf])ndh\b/$1$2_+ndh/g or          # Present participle '+andeh'
        s/\b(\S{2,}?)([CrnAuimz])dh\b/$1$2_+dh/g or               # Past participle '+deh'
        s/\b(\S{2,}?)([Cfsx])th\b/$1$2_+th/g or                   # Past participle '+teh'
        s/\b(gf|kC|hs|rf|bs)t(h|n)\b/$1_+t$2/g or                 # Short +tan verbs, eg. 'rafteh, goftan' gerund or past participle
        s/\b(kr|C|bu|dA|z|rsi|br|di|kn|rsAn|ci)d(nd|i|id|m|im)?\b/$1_+d_+$2/g;  # 'shodand/zadand...' simple past - temp. until resolve file works
        s/\b(xuAh|dAr|kn|Cu|bAC)(d|nd|id|i|im|m)\b/$1_+$2/g;      # future/have - temp. until resolve file works
        s/_\+d_\+\B/_+d/g or  # temp. until resolve file works
        s/_\+t_\+\B/_+t/g;    # temp. until resolve file works

        m/(?:_\+|\+_)/ and $pos_v = 1;


######## Contractions ########
        s/\b([^+ ]{2,}?)([uAi])st(\p{P})/$1$2 Ast$3/g; # normal "[uAi] ast", is often followed by punctuation (eg. mAst vs ...mA Ast.)


##### Noun Section #####
        unless ( $pos_v ) {
          s/\b([^+ ]{2,}?)([uA])i(CAn|C|tAn|mAn)(_\+.*?)?\b/$1$2_+$3$4/g or     # Removes epenthetic yeh before genitive pronominal enclitics
          s/\b([^+ ]{2,}?)([^uAi+ ])(CAn|(?<!s)tAn)(_\+.*?)?\b/$1$2_+$3$4/g or  # Genitive pronominal enclitics
          s/\b([^+ ]+?)([Au])i\b/$1$2_+e/g;                                     # Ezafe preceded by long vowel

          ## Plural suffixes.  They're mutually exclusive, so we short circuit when possible
          s/\b([^+ ]{2,}?)-?hA\b/$1_+-hA/g or             # Nominal plural suffix 'hA'
          s/\b([^+ ]{2,}?)-?hA(_\+\S*?)\b/$1_+-hA$3/g or  # Nominal plural suffix 'hA' plus more suffixes
          s/\b([^+ ]{2,}?)(?<!A)gAn\b/$1h_+An/g or        # Human plural suffix 'An' from stem ending in 'eh'
          s/\b([^+ ]{4,}?)(?<!st)(An)\b/$1_+$2/g or       # Human plural suffix '+An'
          s/\b([mA]\S*?)At\b/$1h_+At/g or                 # Arabic fem plural: +At
          s/\b(\S*?[$ar_chars]\S*?)At\b/$1h_+At/og;       # Arabic fem plural: +At

          m/_\+/ and $pos_n = 1;
        }

##### Adjective Section #####
        unless ( $pos_v || $pos_n ) {
          s/\b([^+ ]+?)-?trin\b/$1_+trin/g or  # Adjectival superlative suffix, optional ZWNJ
          s/\b([^+ ]+?)-?tr\b/$1_+tr/g or      # Adjectival comparative suffix, optional ZWNJ
          s/\b([^+ ]+?)(?<!A)gi\b/$1h_+i/g or  # Adjectival suffix from stem ending in 'eh'
          s/\b([^+ ]+?)([iI])i\b/$1_+i/g or    # '+i' suffix preceded by 'i' (various meanings)
          s/([^+ ]+?)e\b/$1_+e/g;              # An ezafe

          m/_\+/ and $pos_aj = 1;
        }

##### End #####

### Increase recall, but lower precision; also contains experimental regexes
        if ( $recall ) {
### Verbal ###
          s/(\S{2,}?)(?<!A|\+)d_\+i(_\+\S+?)?\b/$1_+d_+i$3/g;                 # Verbal tense suffix 'd' + 2nd person singular 'i'
          s/\b([^+ ]{2,}?(?:r|(?<![Ai])u|(?<![Au])i|n|m|z))d(?!\s)\b/$1_+d/g; # 3rd person singular past verb - voiced
          s/\b([^+ ]{2,}?[fCxs])t(?!\s)\b/$1_+t/g;                            # 3rd person singular past verb - unvoiced

          # s/\b(n?)([^+ ]{2,}?)((?<=r|u|i|A|n|m|z)d|(?<=f|C|x|s)t)(?!\s)\b/$1+_$2_+$3/g; # 3rd person singular past verb & neg.
          s/(\S{2,}?(?:[^+ ]{2}d|[^+ ]{2}[sfCx]t|\bn\+_\S{2,}?|mi\+_\S{2,}?|b\+_\S{2,}?)(?:im|id|nd|m|(?<!A|u)i|d))mAn\b/$1_+mAn/g;   # Verbal Object verb enclitic +mAn
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


### Resolve irregular present-tense verb stem to their past-tense stem
      if (($pos_v or $pos_aux) and $use_irreg_stems) {
        my $stem = $_;
        $stem =~ s/\b[^ ]+\+_([^ ]+?)\b/$1/g;  # Removes prefixes
        $stem =~ s/\b([^ ]+?)_\+[^ ]+\b/$1/g;  # Removes suffixes
        s/\Q${stem}\E/$irreg_stems{$stem}[0]/  if $irreg_stems{$stem};
      }

### Deletes everything but the stem
      if ( $show_only_stem ) {
        s/\b[^ ]+\+_([^ ]+?)\b/$1/g;  # Removes prefixes
        s/\b([^ ]+?)_\+[^ ]+\b/$1/g;  # Removes suffixes
      }

### Show verbal infinitival form
      if (($pos_v or $pos_aux) and $show_infinitival_form) {
        if (m/^C$/) { # Treat shodan differently
          $_ .= 'dn';
        }
        elsif (m/[fsCx]$/) { # Unvoiced infinitival "+tan"
          $_ .= 'tn';
        }
        elsif (m/d$/) { # Verb stem ends in 'd' (eg 'mi-dAdi')
          $_ .= 'n';
        }
        else { # Voiced infinitival "+dan"
          $_ .= 'dn';
        }
      }

    } # ends unless $form eq 'untouched'

### Show parts of speech
    if ( $pos ) {
## Verbal ##
      if ( $pos_v ) {
        s/^(\P{Po}*)(.*?)$/$1${pos_sep}V/;
        my $punct = $2;
        m/b\+_/g            and $_ .= '+SBJN-IMP'; # Subjunctive/imperative 'be'
        m/n\+_/g            and $_ .= '+NEG';      # Negative 'na'
        m/mi-?\+_/g         and $_ .= '+IPFV';     # Imperfective/durative 'mi'
        m/_\+[dt](?![hn])/g and $_ .= '+PST';      # Past tense 'd/t'
        m/_\+[dt]n/g        and $_ .= '+GER';      # Gerund 'dan/tan'
        m/_\+m/g            and $_ .= '+1.SG';     # 1 person singular 'am'
        m/_\+im/g           and $_ .= '+1.PL';     # 1 person plural 'im'
        m/_\+id/g           and $_ .= '+2.PL';     # 2 person plural 'id'
        m/_\+nd/g           and $_ .= '+3.PL';     # 3 person plural 'nd'
        m/_\+C(?!An)/g      and $_ .= '+3.SG.ACC'; # 3 person singular accusative 'esh'
        m/_\+mAn/g          and $_ .= '+1.PL.ACC'; # 1 person plural accusative 'emAn'
        m/_\+tAn/g          and $_ .= '+2.PL.ACC'; # 2 person plural accusative 'etAn'
        m/_\+CAn/g          and $_ .= '+3.PL.ACC'; # 3 person plural accusative 'eshAn'

        m/_\+ndh/g      and $_ .= '+PRPT'; # Present participle 'andeh'
        m/_\+[dt]h/g    and $_ .= '+PSPT'; # Past participle 'deh/teh'
        $_ .= "$punct";
      }

## Nominal ##
      if ( $pos_n ) {
        s/^(\P{Po}*)(.*?)$/$1${pos_sep}N/;
        my $punct = $2;
        m/_\+-?hA/g     and $_ .= '+PL';      # Plural 'hA'
        m/_\+An/g       and $_ .= '+PL.ANIM'; # Plural 'An'
        m/_\+At/g       and $_ .= '+PL';      # Plural 'At'
        m/_\+e/g        and $_ .= '+EZ';      # Ezafe 'e'
        m/_\+C(?!An)/g  and $_ .= '+3.SG.PC'; # 3 person singular pronominal clitic 'esh'
        m/_\+mAn/g      and $_ .= '+1.PL.PC'; # 1 person plural pronominal clitic 'emAn'
        m/_\+tAn/g      and $_ .= '+2.PL.PC'; # 2 person plural pronominal clitic 'etAn'
        m/_\+CAn/g      and $_ .= '+3.PL.PC'; # 3 person plural pronominal clitic 'eshAn'
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
    unless ( $form eq 'linked' ) {
      s/_\+0/ /g;  # Removes epenthetic letters
      s/_\+-/ /g;  # Removes suffix links w/ ZWNJs
      s/_\+/ /g;   # Removes all suffix links
      s/-\+_/ /g;  # Removes prefix links w/ ZWNJs
      s/\+_/ /g;   # Removes all prefix links
    }

### Converts from dehdari transliteration to native script
    if ($output_type ne 'translit') {
      if ($output_type eq 'utf8') {
        tr/ABbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoeOPkiMXIUN~,;?%*\-/اأبپتثجچحخدذرزژسشصضطظعغفقكگلمنوهيَُِآةکیءۀئؤًّ،؛؟٪‍‌/;
      }

      elsif ($output_type eq 'ncr') {
        my %roman2unihtml = (
          'A' => '&#1575;', '|' => '&#1575;', 'B' => '&#1571;', 'b' => '&#1576;', 'p' => '&#1662;', 't' => '&#1578;', 'V' => '&#1579;', 'j' => '&#1580;', 'c' => '&#1670;', 'H' => '&#1581;', 'x' => '&#1582;', 'd' => '&#1583;', 'L' => '&#1584;', 'r' => '&#1585;', 'z' => '&#1586;', 'J' => '&#1688;', 's' => '&#1587;', 'C' => '&#1588;', 'S' => '&#1589;', 'D' => '&#1590;', 'T' => '&#1591;', 'Z' => '&#1592;', 'E' => '&#1593;', 'G' => '&#1594;', 'f' => '&#1601;', 'q' => '&#1602;', 'k' => '&#1705;', 'K' => '&#1603;', 'g' => '&#1711;', 'l' => '&#1604;', 'm' => '&#1605;', 'n' => '&#1606;', 'u' => '&#1608;', 'v' => '&#1608;', 'w' => '&#1608;', 'h' => '&#1607;', 'X' => '&#1728;', 'i' => '&#1740;', 'I' => '&#1574;', 'a' => '&#1614;', 'o' => '&#1615;', 'e' => '&#1616;', '~' => '&#1617;', ',' => '&#1548;', ';' => '&#1563;', '?' => '&#1567;', 'O' => '&#1570;', 'M' => '&#1569;', 'N' => '&#1611;', 'U' => '&#1572;', '-' => '&#8204;', ' ' => ' ', '_' => '_', '+' => '+', "\n" => '<br/>', '.' => '&#8235.&#8234;', );
        my @charx = split(//, $_);
        $_ = '';
        foreach my $charx (@charx) {
          $_ .= $roman2unihtml{$charx};
        }
      }  # ends elsif (ncr)

      elsif ($output_type eq 'cp1256') {
        tr/ABbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoeOPkMXIUN~,;?{}\-i/\xc7\xc3\xc8\x81\xca\xcb\xcc\x8d\xcd\xce\xcf\xd0\xd1\xd2\x8e\xd3\xd4\xd5\xd6\xd8\xd9\xda\xdb\xdd\xde\xdf\x90\xe1\xe3\xe4\xe6\xe5\xed\xf3\xf5\xf6\xc2\xc9\x98\xc1\xc0\xc6\xc4\xf0\xf8\xa1\xba\xbf\xab\xbb\x9d\xec/;

        #  s/\x2e/\xfe\x2e\xfd/g; # Corrects periods to be RTL embedded; broken
      }

      elsif ($output_type eq 'isiri3342') {
        tr/ABbptVjcHxdLrzJsCSDTZEGfqKglmnuhyaoeO\x7cPkiMIUN~,;?%{}\-/\xc1\xf8\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xfe\xf0\xf2\xf1\xc0\xc1\xfc\xda\xe1\xc2\xfb\xfa\xf3\xf6\xac\xbb\xbf\xa5\xe7\xe6\xa1/; }

      elsif ($output_type eq 'arabtex') {
        my %roman2arabtex = (
          'A' => 'A', '|' => 'a', 'b' => 'b', 'p' => 'p', 't' => 't', 'V' => '_t', 'j' => 'j', 'c' => '^c', 'H' => '.h', 'x' => 'x', 'd' => 'd', 'L' => '_d', 'r' => 'r', 'z' => 'z', 'J' => '^z', 's' => 's', 'C' => '^s', 'S' => '.s', 'D' => '.d', 'T' => '.t', 'Z' => '.z', 'E' => '`', 'G' => '.g', 'f' => 'f', 'q' => 'q', 'K' => 'k', 'k' => 'k', 'g' => 'g', 'l' => 'l', 'm' => 'm', 'n' => 'n', 'u' => 'U', 'v' => 'w', 'w' => 'w', 'h' => 'h', 'X' => 'H-i', 'i' => 'I', 'I' => '\'y', 'a' => 'a', 'o' => 'o', 'e' => 'e', 'P' => 'T', '~' => '', ',' => ',', ';' => ';', '?' => '?', 'O' => '^A', 'M' => '\'', 'N' => 'aN', 'U' => 'U\'', '{' => '\lq ', '}' => '\rq ', '-' => '\hspace{0ex}', '.' => '.', ' ' => ' ', '_' => '_', '+' => '+', );
        my @charx = split(//, $_);
        $_ = '';
        foreach my $charx (@charx) {
          $_ .= $roman2arabtex{$charx};
        }

        #  $_ .= '\\\\'; # Appends LaTeX newline '\\' after each line
      }  # ends elsif (arabtex)

      else { die "Perstem error: unrecognized --output type\n\n" . $usage }

      ## Restore temporary Latin doppelgaenger characters to their normal forms
      tr/ⓐ-ⓩⒶ-Ⓩ⓿①-⑨⁆⁓‚;⁇‰⁎‐✢/a-zA-Z01-9~,;?%*\-+/;

      if ($output_type eq 'utf8' && m/[^ \n]/) { # If utf8 & non-empty
        binmode(STDOUT, ":utf8"); # Uses the :utf8 output layer
        $full_line .= "$_ ";
      }
      elsif ( /[^ \n]/ ) { # if arabic-script line is non-empty
        $full_line .= "$_ ";
      }

    } # ends if ($output_type ne 'translit') -- for native Perso-Arabic-script input
    elsif ( /[^ \n]/ ) { # if latin-script line is non-empty
      if ($input_type ne 'translit') {
        ## Deal with latin-script strings from arabic-script input
        tr/ⓐ-ⓩⒶ-Ⓩ⓿①-⑨⁆⁓‚;⁇‰⁎‐✢/a-zA-Z01-9~,;?%*\-+/;
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
brAi	brAi	P
rui	ru_+e	P+EZ
Hti	Hti	P
sui	su_+e	P+EZ
kh	kh	C
Ain	Ain	DT+PROX
On	On	DT+DIST
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
OnhA	OnhA	PRON+3.PL
OnAn	OnAn	PRON+3.PL
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
nmAindh	nmAindh	N
nmAiC	nmAiC	N
nuisndh	nuisndh	N
prundh	prundh	N
xndh	xndh	N
bzrgi	bzrg_+i	N+ATTR
bEid	bEid	A
biCtr	biC	A
digr	digr	A
nhAii	nhAii	A
nhAIi	nhAii	A
frxndh	frxndh	A
milAdi	milAdi	A
Oindh	O_+ndh	A+PRPT
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
OmrikA	OmrikA	N
OmrikAii	OmrikA_+i
AnsAni	AnsAn_+i	N
bnglAdC	bnglAdC	N
thrAn	thrAn	N
pArlmAn	pArlmAn	N
zbAnhAi	zbAn_+hA_+e	N+PL+EZ
zbAnhA	zbAn_+hA	N+PL
kCurhAi	kCur_+hA_+e	N+PL+EZ
kCurhA	kCur_+hA	N+PL
tBsisAt	tBsis_+At	N+PL
mrdm	mrdm	N
dftr	dftr	N
dfAtr	dftr	N
dktr	dktr	N
jAi	jA_+e	N+EZ
ksAni	ks	N+PL+INDEF
OVAr	AVr	N+PL.BROKEN
Amur	Amr	N+PL.BROKEN
AfrAd	frd	N+PL.BROKEN
AfrAdi	frd_+i	N+PL.BROKEN+INDEF
muAd	mAdh	N+PL.BROKEN
ruAbT	rAbTh	N+PL.BROKEN
CrAiT	CrT	N+PL.BROKEN
mnATq	mnTqh	N+PL.BROKEN
mnAbE	mnbE	N+PL.BROKEN
msAIl	msIlh	N+PL.BROKEN
SnAiE	SniEh	N+PL.BROKEN
ntAij	ntijh	N+PL.BROKEN
mll	mlt	N+PL.BROKEN
Hdud	Hd	N+PL.BROKEN
Hquq	Hq	N+PL.BROKEN
mrAsm	rsm	N+PL.BROKEN
AnuAE	nuE	N+PL.BROKEN
muArd	murd	N+PL.BROKEN
EuAml	EAml	N+PL.BROKEN
mrAkz	mrkz	N+PL.BROKEN
Elum	Elm	N+PL.BROKEN
nqAT	nqTh	N+PL.BROKEN
AfkAr	fkr	N+PL.BROKEN
ASul	ASl	N+PL.BROKEN
quAnin	qAnun	N+PL.BROKEN
mnAfE	mnfEt	N+PL.BROKEN
EnASr	EnSr	N+PL.BROKEN
ATrAf	Trf	N+PL.BROKEN
xTuT	xT	N+PL.BROKEN
EuArD	EArDh	N+PL.BROKEN
AHzAb	Hzb	N+PL.BROKEN
AEDAi	EDu_+e	N+PL.BROKEN+EZ
mrA	mn rA
trA	tu rA
cist	ch Ast
kjAst	kjA Ast
xuAhd	xuAh_+d	AUX+3.SG
bAid	bA_+d	AUX+3.SG
CAid	CA_+d	AUX+3.SG
Omdh	Om_+dh	V+PSPT
Ourdh	Our_+dh	V+PSPT
Ast	Ast	V.3.SG.PRS
bAxt	bAx_+t	V+PST.3.SG
brdh	br_+dh	V+PSPT
bud	bu_+d	V+PST.3.SG
budh	bu_+dh	V+PSPT
budn	bu_+dn	V+GER
budnd	bu_+d_+nd	V+PST+3.PL
Cdh	C_+dh	V+PSPT
Cdn	C_+dn	V+GER
Cud	Cu_+d	V.PRS+3.SG
Cundh	Cu_+ndh	V.PRS+PRPT
dACt	dAC_+t	V+PST.3.SG
dACth	dAC_+th	V+PSPT
dAdh	dA_+dh	V+PSPT
dAdn	dA_+dn	V+GER
dAdnd	dA_+d_+nd	V+PST+3.PL
midAd	mi-+_dA_+d	V+IPFV+PST.3.SG
mi-dAd	mi-+_dA_+d	V+IPFV+PST.3.SG
dAnst	dAns_+t	V+PST.3.SG
dArd	dAr_+d	V.PRS+3.SG
dhd	dh_+d	V.PRS+3.SG
dhndh	dh_+ndh	V.PRS+PRPT
didn	di_+dn	V+GER
didh	di_+dh	V+PSPT
binndh	bin_+ndh	V.PRS+PRPT
gft	gf_+t	V+PST.3.SG
gLACt	gLAC_+t	V+PST.3.SG
gLACth	gLAC_+th	V+PSPT
gLCth	gLC_+th	V+PSPT
grfth	grf_+th	V+PSPT
grft	grf_+t	V+PST.3.SG
iAft	iAf_+t	V+PST.3.SG
kCt	kC_+t	V+PST.3.SG
knnd	kn_+nd	V.PRS+3.PL
knndh	kn_+ndh	V.PRS+PRPT
knd	kn_+d	V.PRS+3.SG
krdn	kr_+dn	V+GER
krdh	kr_+dh	V+PSPT
krdnd	kr_+d_+nd	V	V+PST+3.PL
hst	hs_+t	V+PST.3.SG
nCdh	n+_C_+dh	V+NEG+PSPT
nist	n+_Ast	V+NEG+3.SG.PRS
ntuAnst	ntuAns_+t	V+PST.3.SG
prdAxt	prdAx_+t	V+PST.3.SG
rft	rf_+t	V+PST.3.SG
sAxt	sAx_+t	V+PST.3.SG
sAxth	sAx_+th	V+PSPT
tuAnst	tuAns_+t	V+PST.3.SG
xuAst	xuAs_+t	V+PST.3.SG
zdh	z_+dh	V+PSPT
zdn	z_+dn	V+GER
zdnd	z_+d_+nd	V+PST+3.PL
znndh	zn_+ndh	V.PRS+PRPT
