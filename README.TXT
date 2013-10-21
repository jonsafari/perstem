Perstem:  Persian stemmer (c) 2004-2013  Jon Dehdari - GPL v.3

Usage:    perl perstem.pl [options] < input > output

Function:  Persian (Farsi) stemmer, morphological analyzer, transliterator,
           and partial part-of-speech tagger.  Input may be encoded
           as Perso-Arabic script UTF-8, ISIRI 3342, Windows-1256,
           SGML/HTML/XML-style numeric character references (ncr), or
           dehdari-transliterated latin-script text.  Use the -i flag
           to specify input encoding.  Output is handled similarly.

Options:
 -f, --form <x>         Output forms as one of the following:
                          dict: as they appear in a dictionary (default)
                          linked: show all morphemes, linked together
                          unlinked: show all morphemes as separate tokens
                          untouched: don't stem/analyze; mostly for char-set conversion
     --flush            Autoflush buffer output after every line
 -h, --help             Print this usage
 -i, --input <type>     Input character encoding type {cp1256,isiri3342,ncr,
                        translit,utf8} (default: utf8)
     --irreg-stem {0|1} Resolve irregular present-tense verb stems to their
                        past-tense stems (eg. kon -> kar).  (default: 1 == true)
 -n, --noroman          Delete all non-Arabic script characters (eg. HTML tags)
 -o, --output <type>    Output character encoding type {arabtex,cp1256,
                        isiri3342,ncr,translit,utf8} (default: utf8)
 -p, --pos              Tag inflected words for parts of speech
     --pos-sep <char>   Separate words from their parts of speech by <char>
                        (default: "/" )
 -r, --recall           Increase recall by parsing ambiguous affixes; may lower
                        precision
     --skip-comments    Skip commented-out lines, without printing them
 -s, --stem             Return only word stems
 -t, --tokenize {0|1}   Tokenize punctuation (default: 1 == true)
 -u, --unvowel          Remove short vowels
 -v, --version          Print version
 -z, --zwnj {0|1}       Insert Zero Width Non-Joiners where they should be (default: 1 == true)



Acknowledgements: Thanks to Jace Livingston, David Zajic, and Corey Miller for their
                  comprehensive error analysis and other suggestions.
                  Thanks to Jay Ritch and Artyom Lukanin for spotting bugs.



Romanized transliteration input table:

Roman	Unicode-Name
______________________________________________________
A	ARABIC LETTER ALEF
b	ARABIC LETTER BEH
p	ARABIC LETTER PEH 
t	ARABIC LETTER TEH
V	ARABIC LETTER THEH
j	ARABIC LETTER JEEM
c	ARABIC LETTER TCHEH
H	ARABIC LETTER HAH
x	ARABIC LETTER KHAH
d	ARABIC LETTER DAL
L	ARABIC LETTER THAL
r	ARABIC LETTER REH
z	ARABIC LETTER ZAIN
J	ARABIC LETTER JEH
s	ARABIC LETTER SEEN
C	ARABIC LETTER SHEEN
S	ARABIC LETTER SAD
D	ARABIC LETTER DAD
T	ARABIC LETTER TAH
Z	ARABIC LETTER ZAH
E	ARABIC LETTER AIN
G	ARABIC LETTER GHAIN
f	ARABIC LETTER FEH
q	ARABIC LETTER QAF
K	ARABIC LETTER KAF (for Arabic)
k	ARABIC LETTER KEHEH
g	ARABIC LETTER GAF
l	ARABIC LETTER LAM
m	ARABIC LETTER MEEM
n	ARABIC LETTER NOON
u	ARABIC LETTER WAW
h	ARABIC LETTER HEH
y	ARABIC LETTER YEH (for Arabic)
i	ARABIC LETTER FARSI YEH 
a	ARABIC FATHA
o	ARABIC DAMMA
e	ARABIC KASRA
O	ARABIC LETTER ALEF WITH MADDA ABOVE
B	ARABIC LETTER ALEF WITH HAMZA ABOVE
M	ARABIC LETTER HAMZA
X	ARABIC LETTER HEH WITH YEH ABOVE
I	ARABIC LETTER YEH WITH HAMZA ABOVE
U	ARABIC LETTER WAW WITH HAMZA ABOVE
P	ARABIC LETTER TEH MARBUTA
N	ARABIC FATHATAN (Tanvin)
~	ARABIC SHADDA (Tashdid)
,	ARABIC COMMA
;	ARABIC SEMICOLON
?	ARABIC QUESTION MARK
.	FULL STOP (Period)
-	ZERO WIDTH NON-JOINER
