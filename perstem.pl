#! /usr/bin/perl
# Written by Jon Dehdari 2004
# Perl 5.8
# Stemmer and Morphological Parser for Persian
# The license is the GPL (www.fsf.org)

# The format of the resolve.txt file is as follows:
# 1. Mokassar: 		'ktb	ktAb'    OR    'ktb	ktAb_+PL'
# 2. Preparsed (speed):	'krdn	kr_+dn'
# 3. Don't stem:	'bArAn	bArAn'
# 4. Stop word:		'u	'

use strict;
#use diagnostics;


my $resolve_file = "resolve.txt";
my $line;
my %resolve;
my @resolve;
my $resolve;
my $ar_chars    = "EqHSTDZLVU";
#my $longvowel    = "Aui]";


open RESOLVE, "$resolve_file";

while ($resolve = <RESOLVE>) {
    chomp $resolve;
    @resolve = split /\t/, $resolve;
    %resolve = ( %resolve, "$resolve[0]" => "$resolve[1]" , );
}

while ($line = <>) {
chomp $line;

if ( exists($resolve{$line})) { print "$resolve{$line}\n";}
else 
{

## If these regular expressions are readable to you, you need to check in to a psychiatric ward!


##### Verb Section #####
# todo: be+, 3Spast-tense

######## Verb Prefixes ########
    $line =~ s/^n(.{2,}?(?:im|id|nd|m|(?!A|u)i|d|(?:r|u|i|A|n|m|z)dn|(?:f|C|x|s)tn)(?:mAn|tAn|CAn|C)?)$/n+_$1/;    # NEGATIVE verb prefix 'n+'
    $line =~ s/(n\+_|\b)mi-(.{2,}?(?:im|id|nd|m|(?!hA)i|d)(?:mAn|tAn|CAn|C)?)$/$1mi-+_$2/;    # DURATIVE verb prefix 'mi+'
    $line =~ s/(n\+_|\b)mi(?!-)(.{2,}?(?:im|id|nd|m|(?!hA)i|d)(?:mAn|tAn|CAn|C)?)$/$1mi+_$2/;    # DURATIVE verb prefix 'mi+'

######## Verb Suffixes ########
    $line =~ s/(.*?(?:..d|..(?:s|f|C|x)t|^n\+_.{2,}?|mi\+_.{2,}?)(?:im|id|nd|m|(?!A|u)i|d))(mAn|tAn|CAn|C)$/$1_+$2/;   # Verbal Object verb suffix
    $line =~ s/(^n\+_.{2,}?|^.?mi\+_.{2,}?)(u|A|i)(i|I)(im|id|i)(_\+.*)?$/$1$2_+0$4$5/;    # Removes epenthesized 'i/I' before Verbal Person suffixes 'im/id/i'
   $line =~ s/(^n\+_.{2,}?|^.?mi\+_.{2,}?)(u|A)i(nd|d|m)(_\+.*?)?$/$1$2_+0$3$4/;    # Removes epenthesized 'i' before Verbal Person suffixes 'm/d/nd'
    $line =~ s/(.*?(?:..d|..(?:s|f|C|x)t|^n\+_.{2,}?|mi\+_.{2,}?))(im|id|nd|m|(?!A|u)i|d)(_\+.*?)?$/$1_+$2$3/;    # Verbal Person verb suffix

    $line =~ s/(.{2,}?)(r|u|i|A|n|m)dn$/$1$2_+dn/;      # Verbal Infinitive '+dan'
    $line =~ s/(.{2,}?)(f|C|x|s)tn$/$1$2_+tn/;          # Verbal Infinitive '+tan'
    $line =~ s/(.{2,}?)(i|n|A|u|z|r|b|h|s|k|C|f)ndh$/$1$2_+ndh/;    # Verbal present participle '+andeh'
    $line =~ s/(.{2,}?)(C|r|n|A|u|i|m|z)dh$/$1$2_+dh/;  # Verbal past participle '+deh'
    $line =~ s/(.{2,}?)(C|f|s|x)th$/$1$2_+th/;         # Verbal past participle '+teh'

    $line =~ s/^(C|z|kr|bu|dA|\]ur|di|br|\]m|mr|kn|ci)(dn|dh)$/$1_+$2/;    # 'shodan/zadan' Infinitive or Verbal past participle

##### Noun Section #####

    $line =~ s/^([^+]{2,}?)(?!A)gAn$/$1h_+An/;  # Nominal PLURAL suffix from stem ending in 'eh'
#   $line =~ s/^([^+]{2,}?)(hA|-hA|An)$/$1_+$2/;# Nominal PLURAL suffixes including '+An' - Use with caution (+recall, -precision)
    $line =~ s/^([^+]+?)(A|u)i$/$1$2_+e/;       # Ezafe preceded by long vowel
    $line =~ s/^([^+]{2,}?)(hA|-hA)$/$1_+$2/;   # Nominal PLURAL suffix
    $line =~ s/^([^+]{2,}?)(hA|-hA)(_\+.*)$/$1_+$2$3/;   # Nominal PLURAL suffix
    $line =~ s/^(.*?[$ar_chars].*?)At$/$1_+h/;  # Arabic plural: +At
    $line =~ s/^((?:m|\|).*?)At$/$1_+h/;        # Arabic plural: +At
    $line =~ s/^(.*?[$ar_chars].*?)t$/$1_+t/;   # Arabic fem: +at
    $line =~ s/^(m.*?)t$/$1_+t/;                # Arabic fem: +at
#   $line =~ s/^([^+]+?)i$/$1_+i/;              # '+i' suffix - Use With Caution (+recall, -precision)


##### Adjective Section #####

    $line =~ s/^([^+]+?)trin$/$1_+trin/;  # Adjectival Superlative suffix
    $line =~ s/^([^+]+?)tr$/$1_+tr/;      # Adjectival Comparative suffix
    $line =~ s/^([^+]+?)(?!A)gi$/$1h_+i/; # Adjectival suffix from stem ending in 'eh'
    $line =~ s/^([^+]+?)(i|I)i$/$1_+i/;   # '+i' suffix preceded by 'i' (various meanings)

##### End #####

    print "$line\n";

} # ends else
} # ends while (<>)
