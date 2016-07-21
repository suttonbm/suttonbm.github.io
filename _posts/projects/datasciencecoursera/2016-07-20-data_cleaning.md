---
title: "Coursera Capstone - Week 2"
date: 2016-07-20
author: suttonbm
layout: post
categories:
  - projects
tags:
  - coursera
  - data.science
  - R
project: datasciencecoursera.capstone
excerpt: >
  Improved Data Cleaning...
---



Over the past couple of days I've put a lot of effort into improving my data cleaning algorithm. I realized pretty quickly when I started generating n-gram models that the raw data just has a ton of little issues.  For example, there are many locations where a special unicode apostrophe character was interpreted as a Windows-1252 or ISO-8859 string, and ended up appearing as a random sequence of three unicode characters.  What a nightmare... [This site](http://www.i18nqa.com/debug/utf8-debug.html) was a lifesaver.

Other factors I considered with the improved cleaning algorithm are:

  * Removal of various special non-latin characters scattered throughout the corpus...
  * Removal of numbers - integer _and_ decimal
  * Treatment of apostrophes - do I include the full contraction as a feature or not?
  * How to identify "foreign" words and remove them so they aren't predicted
  * How to identify "missing" words so they can be predicted
  * Stopword removal - to do, or not to do?
  * Sentence detection - I don't really want to predict words across sentences boundaries.
  * Stemming - same as stopwords.

Also, I pretty much abandoned trying to stick with the "corpus" methodology that most packages follow. There's just too much discrepancy between how various packages handle things like text cleanup to make it very useful. I do end up loading the cleaned data into a `quanteda` corpus for generating n-gram models, but the whole corpus is pretty much a blob of text up to that point.

One final thought - it would have been pretty overwhelming to develop these algorithms on the whole corpus, so I just used a small (p=0.001) subsample to test out my algorithms. I also worked through the process step-by-step in the console, using an external diff tool to compare text files before and after applying operations.  Once I was sure I had a sequence of steps working the way I wanted, I then copied over the algorithm into a script.

The whole source code is up on [Github](https://github.com/suttonbm/datasciencecoursera_Capstone/blob/master/script/loadCorpusFromFile.R), but I've included some snippets here where relevant.

### Cleaning up Squirrelly UTF-8

First things first, I had to fix all the apostrophe train wrecks, remove the weird UTF-8 characters that some bloggers apparently love to use, and figure out how to get rid of numbers. The easiest option I could think of was to use Regex to filter the input data. I used the following function, applied on the rawtext input, to do this for me:


```r
removeSpecialCharacters <- function(x) {
  validchars <- "[^a-zA-Z[:space:]\\.']"
  decnum <- "[[:digit:]]*\\.[[:digit:]]+"
  apost1 <- "[\U0027\U0060\U00B4\U2018\U2019]"
  apost2 <- "\U00E2\U20AC\U2122"
  apost3 <- "\U00E2\U20AC\U02DC"
  x <- tolower(x)
  # Replace alternative sentence markers with periods
  x <- gsub("[?!]", ".", x)
  # Replace unicode apostrophe variants
  x <- gsub(apost1, "'", x)
  # Replace unicode errors for apostrophes
  x <- gsub(apost2, "'", x)
  x <- gsub(apost3, "'", x)
  # Remove decimal numbers with the period to avoid sentence detection errors
  x <- gsub(decnum, " ", x)
  # Remove everything else that's not a "valid" latin character
  x <- gsub(validchars, " ", x)
  x
}
```

Note the three different filters I applied for apostrophes.  I probably could have figured out a way to do this with one call to gsub, but I got lazy and just did it three times.  I figure processing time isn't really critical for data cleanup - ideally I only have to do it once...

Now, since I just replaced all those weird UTF-8 characters and numbers with whitespace, I have some periods just floating around in space. I created a second function to clean that up and eliminate leading whitespace around periods to allow sentence recognition to work:


```r
fixApostAndPeriods <- function(x) {
  # Remove space around periods
  x <- gsub("\\s+\\.\\s+", ".", x)
  # Remove repeated periods
  x <- gsub("\\.+", ".", x)
  # Add trailing space to periods
  x <- gsub("\\.", ". ", x)
  # Add leading space to apostrophes to create features (`he's` -> `he`,`'s`)
  #x <- gsub("'", " '", x)
  x
}
```

Side note - these functions are intended to be use with `lapply()`.

The observant may notice that one line of code that is commented out - that was my attempt to make contractions separate features in the n-gram data.  However, I ran into a couple issues with this approach that ultimately led me to use contractions as single featues:

  * Most contractions, such as "don't", and "couldn't", include some suffix modifying the first word in addition to the characters following the apostrophe.  Splitting on the apostrophe wouldn't capture this behaviour.
  * Quanteda didn't play nice. When I tried to include terms like `'s` as a separate feature, it actually split on the punctuation, creating two terms from one.  `don't` would become `don_'_t`.  Not what I was going for.

### Missing and Foreign Words

To address missing and foreign words, I first had to figure out how to identify them. The simple answer is to use a dictionary. I downloaded a list of english words from [SCOWL](http://wordlist.aspell.net), which is also the dictionary behind spellchecker "Hunspell".  After making a few formatting changes and loading into R, I made quick work of identifying foreign and missing words by making some assumptions:

  * Words in the dictionary and not in the corpus were MISSING
  * Words in the corpus and not in the dictionary were FOREIGN

We can of course debate whether this is the *best* answer, but it certainly is *an* answer.  For example, "foreign" words could also be misspelled english words or obscure words not included in the dictionary.  However, I'm also relying on the data set being large enough to make such considerations irrelevant.  Right now the script is just reporting back a list of missing words; I haven't figured out how to make use of it quite yet.

I also made use of stemming to simplify the list of missing words.  My rationale, relying once again on a large number of data points, is that words missing from the corpus are most likely uncommon words. Including every possible part of speech related to a common root may not provide much value to a user.


```r
missingWords <- dict[!(dict %in% data)]
missingWords <- unique(quanteda::wordstem(missingWords, language="english"))
```

### Stopword Removal

The debate about stopword removal for predictive text selection seems to make a case for both sides.  I've seen some students include them and some students remove them.  My opinion is that a predictive keyboard is not intended to eliminate user input, just to reduce it.  For that reason, I believe providing predictions of "it", "and", or "I" are not very useful.  By removing stopwords, I rely on the user to input them manually, and the prediction will be made based on surrounding words.

### Stemming

Stemming... I didn't really understand how this was useful at first. Originally I struggled to understand how implementing stemming could possibly work if it meant my code would suggest to use "colaborat" instead of "collaborate".  However, today I learned about the `stemCompletion()` function in the `tm` package.  Using this it is possible to recover the full word and make reasonable recommendations.  I'll be using stemming in my project to reduce the overall size of the text database

### Next Steps

As I move towards generating my first n-gram model, the following tasks stick out as next steps:

  * Read and understand how to do interpolation and smoothing for unknown n-grams
  * Figure out how to represent missing vocabulary and unknown words
    * Do I want to try and include missing words?
    * Do I just ignore unknown words in the corpus?
    * Should I implement a "fuzzy" string match algorithm? Will this be too slow?
  * How can I index the database of n-grams to improve search speed?
    * Other students seem to have struggled with the whole n-gram dataset being constantly loaded into memory.
    * Is there a way to improve this without increasing the memory allocation required for the app?

<p><a id='bib-JSSv025i05'></a><a href="#cite-JSSv025i05">[1]</a><cite>
I. Feinerer, K. Hornik and D. Meyer.
&ldquo;Text Mining Infrastructure in R&rdquo;.
In: <em>Journal of Statistical Software</em> 25.1 (2008), pp. 1&ndash;54.
ISSN: 1548-7660.
DOI: <a href="http://dx.doi.org/10.18637/jss.v025.i05">10.18637/jss.v025.i05</a>.
URL: <a href="https://www.jstatsoft.org/index.php/jss/article/view/v025i05">https://www.jstatsoft.org/index.php/jss/article/view/v025i05</a>.</cite></p>

<p><a id='bib-W98-1218'></a><a href="#cite-W98-1218">[2]</a><cite>
D. M. Powers.
&ldquo;Applications and Explanations of Zipf's Law&rdquo;.
In: <em>New Methods in Language Processing and Computational Natural Language Learning</em> (1998), pp. 151&ndash;160.
URL: <a href="http://aclweb.org/anthology/W98-1218">http://aclweb.org/anthology/W98-1218</a>.</cite></p>

<p><a id='bib-CBO9781139058452A007'></a><a href="#cite-CBO9781139058452A007">[3]</a><cite>
A. Rajaraman and J. D. Ullman.
&ldquo;Data Mining&rdquo;.
In: 
<em>Mining of Massive Datasets</em>.
Ed. by C. B. Online.
Cambridge Books Online.
Cambridge University Press, 2011, pp. 1&ndash;17.
ISBN: 9781139058452.
URL: <a href="http://dx.doi.org/10.1017/CBO9781139058452.002">http://dx.doi.org/10.1017/CBO9781139058452.002</a>.</cite></p>
