---
title: "Coursera Capstone - Week 2"
date: 2016-07-16
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
  Exploratory Data Analysis
---



There are two tasks for week 2 of the SwiftKey Natural Language Processing Capstone for the Coursera Data Science specialization:

  * Exploratory Data Analysis
  * Simple Language Modeling

In this post, I'll cover my exploratory data analysis, and will follow up on the simple model construction in the [next post]({{ base.url }}/2016/07/nlp_simple_model/)

For more information on how I got to this point, refer to earlier posts about [NLP]({{ base.url }}/2016/06/nlp_intro/), [sampling data]({{ base.url }}/2016/06/sampling_data/), and [cleaning/tokenizing data]({{ base.url }}/2016/06/tokenize_clean_data/).

The data for this project are located at: [Dataset](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip)

### Introduction

The goal of exploring the dataset (corpus) is to get a relative sense for what the data looks like and perhaps draw some qualitative conclusions about the data itself prior to generating a predictive model. There are six questions posed by the Coursera Course staff:

  * Some words are more frequent than others - what are the distributions of word frequencies?
  * What are the frequencies of 2-grams and 3-grams in the dataset?
  * How many unique words do you need in a frequency sorted dictionary to cover 50% of all word instances in the language? 90%?
  * How do you evaluate how many of the words come from foreign languages?
  * Is there a way to improve coverage by identifying words that may not be in the corpora?
  * Can you somehow use a smaller number of words to cover the same phrases?

#### Word Frequency Distribution

Let's take a look at the frequency distribution of words for varying corpus sizes.  I've loaded some data into `word.freq.df` containing this information.  In addition to plotting the empirical data gathered from the corpora, I'll also generate and overlay a best-fit Zipf distribution.



```r
library(ggplot2)
library(zipfR)

genModel <- function(data, id) {
  input <- spc(data)
  model <- lnre("fzm", input, exact=F)
  model <- lnre.spc(model, N(model))
  model$id <- id
  model
}

model.blog1 <- genModel(word.freq.df$count[word.freq.df$size == 251920], "1")
model.blog2 <- genModel(word.freq.df$count[word.freq.df$size == 1337840], "2")
model.blog3 <- genModel(word.freq.df$count[word.freq.df$size == 2557728], "3")

model <- rbind(model.blog1, model.blog2, model.blog3)

ggplot() +
  geom_point(data = word.freq.df, aes(x=n, y=count, colour=size)) +
  geom_line(data = model, aes(x=m, y=Vm, group=id)) +
  scale_x_log10(limits = c(1, 100)) +
  scale_y_log10(limits = c(10, 100000)) +
  xlab("Feature Count") +
  ylab("Feature Rank (n)") +
  ggtitle("Frequency of Features vs Rank") +
  scale_colour_discrete(name="Corpus Size (Bytes)")
```

![center](http://i.imgur.com/frSvIcr.png)

We can observe from the plot that the zipf distribution is a good fit for the higher frequency terms, but it seems that the distribution underestimates the number of terms in the tail.

#### Frequency of N-Gram Terms

Let's take a look at the frequency of N-Gram terms for a fixed corpus size.  Again, I've already loaded data into a variable, `tokensVsNGram`:



```r
ggplot(data=tokensVsNGram, aes(x=n, y=feats)) +
  geom_point() +
  xlab("Number of Features") +
  ylab("N-Gram (N)") +
  ggtitle("Number of Features vs Selection of N")
```

![center](http://i.imgur.com/vYo6P0v.png)

We see from the plot above that total number of features extracted from the corpus peaks rises quickly to a peak at N=4, then slowly falls with increasing N.

It may also be interesting to investigate the frequency-rank plot for different parameters.  I've processed some additional data and stored it in the variable `freqRankVsNGram`.



```r
ggplot(data=freqRankVsNGram, aes(x=n, y=count, colour=NGram)) +
  geom_point() +
  scale_x_log10(limits=c(1, 1000)) +
  scale_y_log10() +
  stat_smooth(method = "lm", formula = y~x, level = 0.9) +
  xlab("Feature Rank") +
  ylab("Feature Count") +
  ggtitle("Frequency of Features vs N")
```

![center](http://i.imgur.com/1NHH9sX.png)

We can see that although N=3 yields the largest total number of features, the features still appear with a lower maximum frequency than words or bigrams.

#### Unique Word and Frequency

How many words are needed to cover 50% of language use? 90%? We can examine this fairly easily by generating a CDF plot of the frequency-rank list:


```r
words.df <- TokensVsNGram.lst[['1.df']]
rownames(words.df) <- NULL
words.df$freq <- words.df$count / sum(words.df$count)
words.df$n <- seq_along(words.df$count)
words.df$cdf <- cumsum(words.df$freq)

head(words.df)
```

```
##   ngram count       freq n        cdf
## 1     . 21771 0.05390369 1 0.05390369
## 2   the 18706 0.04631493 2 0.10021863
## 3   and 11085 0.02744580 3 0.12766442
## 4    to 10635 0.02633162 4 0.15399604
## 5     a  9239 0.02287521 5 0.17687125
## 6    of  8728 0.02161000 6 0.19848126
```

```r
ggplot(data=words.df, aes(x = n, y = cdf)) +
  geom_point() +
  geom_line(aes(y=0.5), color="red") +
  geom_line(aes(y=0.9), color='blue') +
  scale_x_log10() +
  annotation_logticks(side='b') +
  xlab("Feature Rank") +
  ylab("Cumulative Probability of Occurrence")
```

![center](http://i.imgur.com/IafsSNU.png)

Graphically we can see that slightly less than 100 words account for 50% of the language, while somewhere around 5000 words account for 90% of the language.

Let's get the exact number:


```r
(words.50 <- max(words.df$n[words.df$cdf <= 0.5]))
```

```
## [1] 86
```

```r
(words.90 <- max(words.df$n[words.df$cdf <= 0.9]))
```

```
## [1] 5420
```

#### Detection of Foreign Language & Missing Words

The easiest way to identify foreign or missing words would be to utilize an english word dictionary.  There are a variety of sources available online:

  * [WordNet](http://wordnet.princeton.edu)
  * [SCOWL](http://wordlist.aspell.net)
  * Others [here](http://www.math.sjsu.edu/~foster/dictionary.txt) and [here](https://raw.githubusercontent.com/sujithps/Dictionary/master/Oxford%20English%20Dictionary.txt)

An assumption that might be made is that extra terms contained in the corpus but not the dictionary are "foreign", while terms in the dictionary but not in the corpus are missing. The terms could be initialized with values as well:

  * "Dumb": initialize all words to a frequency of 1
  * "POS": initialize words based on part-of-speech frequency, average or minimum
  * "ML": initialize words based on some sort of similarity metric. This could be a machine learning or regression algorithm of some kind looking at things like word similarity, synonyms, and/or part-of-speech.

I've chosen to use the SCOWL dictionary.  The dictionary I used can be found [here](http://downloads.sourceforge.net/wordlist/hunspell-en_US-2016.06.26.zip), and more information can be found at the link above.


```r
dict <- readLines("hunspell/dictionary.txt")
dict <- dict[45:length(dict)]
dict <- unlist(lapply(dict, function(x) tolower(x)))

print(paste("There are",length(dict),"words in the dictionary."))
```

```
## [1] "There are 166456 words in the dictionary."
```

```r
print(paste("There are",length(words.df$ngram),"unique words in the corpus."))
```

```
## [1] "There are 28839 unique words in the corpus."
```

First, let's identify if there are terms in the corpus that are not included in the dictionary:


```r
extraWords <- words.df$ngram[!(words.df$ngram %in% dict)]
extraWords <- as.character(extraWords)

print(paste("There are",length(extraWords),"words in the corpus not included in the dictionary"))
```

```
## [1] "There are 5829 words in the corpus not included in the dictionary"
```

```r
head(extraWords)
```

```
## [1] "." "!" "?" "'" "2" "1"
```

Looks like the first few (most common) "words" included in the corpus aren't words at all - they are numbers.  Maybe the tail will shed some light on foreign words.


```r
tail(extraWords, 20)
```

```
##  [1] "aiden's"     "37th"        "kevie"       "bucktown"    "nowak"      
##  [6] "tarnita"     "lcs"         "15.00"       "siska"       "perfomance" 
## [11] "hirst"       "wynton"      "marsalis"    "eyebolts"    "nicky"      
## [16] "1100"        "d.c"         "rautzhan"    "davalillo's" "lmdb"
```

Interestingly, it looks like even in the tail we don't see foreign words. A few observations I've made about excluded terms are:

  * Some of the foreign words are numbers, not words
  * Some appear to be proper names or abbreviations for words
  * There are a few examples of misspelled words that should normally exist in the corpus

#### Better Coverage, for Less!

One pre-processing step that I did not include in the investigation so far is stemming. Stemming seeks to reduce the number of features by removing suffixes, prefixes, or other parts of families of words.  For example, "run", "running", "runner" might all be simplified to "run".

### References
<p><a id='bib-CBO9781139058452A007'></a><a href="#cite-CBO9781139058452A007">[1]</a><cite>
A. Rajaraman and J. D. Ullman.
&ldquo;Data Mining&rdquo;.
In: 
<em>Mining of Massive Datasets</em>.
Ed. by C. B. Online.
Cambridge Books Online.
Cambridge University Press, 2011, pp. 1&ndash;17.
ISBN: 9781139058452.
URL: <a href="http://dx.doi.org/10.1017/CBO9781139058452.002">http://dx.doi.org/10.1017/CBO9781139058452.002</a>.</cite></p>
