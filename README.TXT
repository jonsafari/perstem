Perstem: Persian stemmer (c) 2004-2007  Jon Dehdari - GPL v.2 or greater

Usage:    perl perstem.pl [options] < input > output

Function: Stemmer and morphological analyzer for the Persian language (Farsi).
          Inflexional morphemes are separated from their roots.  Input may be
	  encoded as Perso-Arabic script UTF-8, ISIRI 3342, CP (Windows) 1256,
	  or romanized text.  Use the -i flag to specify input encoding.  Output
	  is handled similarly.

Options:
  -d, --nostem           Don't stem -- mostly for character-set conversion.
  -h, --help             Print usage.
  -i, --input <type>     Input character encoding type {cp1256,isiri3342,utf8,unihtml}
  -l, --links            Show morphological links.  For example 'mi-xurnd' would appear
                         as 'mi-+_xur_+nd' instead of the default 'mi- xur nd'.
  -n, --noroman          Delete all non-Arabic script characters, such as HTML tags.
  -o, --output <type>    Output character encoding type {arabtex,cp1256,isiri3342,utf8,unihtml}
  -r, --recall           Increase recall by parsing ambiguous affixes, such as the suffix 'i', 
                         the Arabic feminine suffix 'at' (the parsing of this particular affix
			 is only useful for information retrieval index-building), the unvoiced
			 third-person past verbal suffix "t", and some genitive pronominal
			 enclitics.  These letters in the final parts of a word are sometimes
			 affixes and othertimes part of the lexical root.  For example, 'dusti'
			 can either be 'dust+i' "your friend" or 'dusti' "friendship".  Without
			 the -r flag, this word would appear as a single stem.
  -t, --tokenize         Tokenize punctuation.  Thus most non-alphabetic characters such as
                         periods, question marks, quotation marks, etc. are padded with spaces
			 on both sides.
  -u, --unvowel          Remove short vowels.
  -v, --version          Print the current version.
  -w, --root             Return only word roots.  For example 'mi-xurnd' would appear as 'xur'.
  -z, --zwnj             Insert Zero Width Non-Joiners where they should be, but weren't.
                         For example, 'mixurnd' would appear as 'mi- xur nd'.


Romanized input table:

Roman	Unicode-Name
______________________________________________________
-	ZERO WIDTH NON-JOINER
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
]	ARABIC LETTER ALEF WITH MADDA ABOVE
|	ARABIC LETTER ALEF (Initial)
M	ARABIC LETTER HAMZA
X	ARABIC LETTER HEH WITH YEH ABOVE
I	ARABIC LETTER YEH WITH HAMZA ABOVE
U	ARABIC LETTER WAW WITH HAMZA ABOVE
P	ARABIC LETTER TEH MARBUTA
N	ARABIC FATHATAN (TANVIN)
~	ARABIC SHADDA (TASHDID)
,	ARABIC COMMA
;	ARABIC SEMICOLON
?	ARABIC QUESTION MARK
.	FULL STOP (PERIOD)

