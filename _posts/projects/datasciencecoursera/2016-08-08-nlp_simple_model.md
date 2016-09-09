---
title: "Coursera Capstone - Week 2"
date: 2016-08-08
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
  Creating a Simple Predictive Model
---



There are two tasks for week 2 of the SwiftKey Natural Language Processing Capstone for the Coursera Data Science specialization:

  * Exploratory Data Analysis
  * Simple Language Modeling

In this post, I'll cover creation of a simplified predictive model.

The data for this project are located at: [Dataset](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip)

### Introduction

In previous posts, I've discussed how we can parse language data, perform some filtering and data cleaning, and convert it to a form suitable for interpretation/processing by a computer (namely, through tokenization).  Now we have to put that data to work.  The goal is to predict the next word in a given sentence fragment with the highest accuracy possible.  As I'll discuss further down, there are a number of ways to perform this task - some are very straightforward, while others require additional processing and model training.

Since this post is intended only to cover simple model generation, I'll leave discussion of more complex models to a [future post]({{ base.url }}/2016/08/nlp_full_model).

### Simplest Model - Word Frequency Prediction

In the previous post, we looked at the distribution of terms in a document and found that the frequency of terms followed a Zipf distribution.  The number of times a word appears in the corpus is inversely proportional to its rank relative to other words.  Thus, the most frequent word in the corpus appears about twice as often as the next most frequent word.  It is not unreaonable, then, to suggest that predicting the next word based on word frequency might provide pretty decent results.

Let's give it a try.  First, I need to read in the corpus, split tokens, and summarize as a document frequency matrix:


```r
source("script/loadCorpusFromFile.R")
source("script/generateNGrams.R")
source("script/generateFeaturesDF.R")

dataFile <- "data/en_US.blogs.txt.0.001"
corpus <- loadCorpusFromFile(dataFile)
```

```
## [1] "Loading data from file..."
## [1] "Removing special characters..."
## [1] "Tokenizing..."
## [1] "Removing expletives..."
## [1] "Processing contractions..."
## [1] "Removing unknown words..."
## [1] "Applying sentence recognition..."
```

```r
tokens <- generateNGrams(corpus, n=1)
words.df <- generateFeaturesDF(tokens)

head(words.df)
```

```
##   ngram count
## 1 <BOS>  9180
## 2 <EOS>  2295
## 3   the  1882
## 4   and  1093
## 5    to  1009
## 6     i   888
```

The first two terms are special terms indicating the start and end of the sentence, and `<UNK>` indicates a word that was not recognized as an english word in the corpus.  If we throw out these special terms, the top five most frequent words in the corpus are:


```r
words.df <- words.df[!(words.df$ngram %in% c('<BOS>','<EOS>','<UNK>')), ]
words.df$rank <- seq_along(words.df$count)
words.df$pct.total <- words.df$count/sum(words.df$count)
head(words.df, 5)
```

```
##   ngram count rank  pct.total
## 3   the  1882    1 0.05106083
## 4   and  1093    2 0.02965435
## 5    to  1009    3 0.02737533
## 6     i   888    4 0.02409246
## 7     a   884    5 0.02398394
```

For a randomly selected sentence fragment, if we predict that the next word is one of the top five words in this list, we would expect to be correct about 16% of the time.  Not bad for a model which makes the same prediction every time.  We can verify with a quick simulation over 0.1% of the blogs corpus:


```r
source('script/predictFromString.R')
source('script/benchmark.R')
```

```
## Note: no visible binding for global variable 'list.name' 
## Note: no visible binding for global variable 'score' 
## Note: no visible binding for global variable 'max.score' 
## Note: no visible binding for global variable 'hit.count.top5' 
## Note: no visible binding for global variable 'total.count' 
## Note: no visible binding for global variable 'hit.count.top3' 
## Note: no visible binding for global variable 'total.count' 
## Note: no visible binding for global variable 'hit.count.top1' 
## Note: no visible binding for global variable 'total.count' 
## Note: no visible binding for global variable 'total.runtime' 
## Note: no visible binding for global variable 'total.count' 
## Note: no visible binding for global variable 'total.count'
```

```r
benchmark(predictFromInts, method='dumbDict')
```

```
## Overall top-5 score:     12.27 %
## Overall top-1 precision: 0.00 %
## Overall top-3 precision: 14.20 %
## Overall top-5 precision: 20.50 %
## Average runtime:         2.44 msec
## Number of predictions:   634
## Total memory used:       4.40 MB
## 
## Dataset details
##  Dataset "data" (51 lines, 838 words, hash c1bb1c56b0c4a151f92ab57279c930a21db643389b99485dccc15caec7daa9ff)
##   Score: 12.27 %, Top-1 precision: 0.00 %, Top-3 precision: 14.20 %, Top-5 precision: 20.50 %
```

Although the result is slightly worse than predicted, it is still remarkably good considering our data frame includes over 6800 different words! Plus, this establishes a good baseline to compare against for future models.

### Next Model: Dumb Bigrams/Trigrams

One method we can use to improve the results is to give our model a sense of "memory". Rather than simply choosing the most likely words to appear in the corpus, we can condition the result on the preceding word or words.

To put this in math speak, consider that predicting the next word based only on frequency.  The probability of a particular word, e.g. 'the' can be given by:

$$$
P('the') = \frac{count('the')}{count(*)}
$$$

Note that the probability of 'the' appearing in the corpus does not depend on what word comes before it!  Let's say the last word in the given sentence fragment is 'and'.  We could augment our estimate based on the likelihood of 'the' appearing given that it follows 'and':

$$$
P('the'|'and') = \frac{count('and the')}{count('and *')}
$$$

Let's take a look at how prediction accuracy is affected by using one (bigram) or two (trigram) preceding words for prediction:


```r
benchmark(predictFromInts, method='dumbBigram')
```

```
## Overall top-5 score:     3.85 %
## Overall top-1 precision: 1.58 %
## Overall top-3 precision: 4.26 %
## Overall top-5 precision: 5.36 %
## Average runtime:         133.97 msec
## Number of predictions:   634
## Total memory used:       4.40 MB
## 
## Dataset details
##  Dataset "data" (51 lines, 838 words, hash c1bb1c56b0c4a151f92ab57279c930a21db643389b99485dccc15caec7daa9ff)
##   Score: 3.85 %, Top-1 precision: 1.58 %, Top-3 precision: 4.26 %, Top-5 precision: 5.36 %
```

```r
benchmark(predictFromInts, method='dumbTrigram')
```

```
## Overall top-5 score:     0.60 %
## Overall top-1 precision: 0.00 %
## Overall top-3 precision: 0.95 %
## Overall top-5 precision: 0.95 %
## Average runtime:         368.17 msec
## Number of predictions:   634
## Total memory used:       4.40 MB
## 
## Dataset details
##  Dataset "data" (51 lines, 838 words, hash c1bb1c56b0c4a151f92ab57279c930a21db643389b99485dccc15caec7daa9ff)
##   Score: 0.60 %, Top-1 precision: 0.00 %, Top-3 precision: 0.95 %, Top-5 precision: 0.95 %
```

Uh-oh, looks like something went wrong.  Intuitively, one would think that using a bigram or trigram model would improve performance.  We're capturing *some* context, so what is going on?  The problem is **data sparsity**.  The training data used is simply not large enough to accurately represent the language.  We'll discuss this issue further in a [future post]({{ base.url }}/2016/08/nlp_data_smoothing/).

### Final Simple Model: Stupid Backoff

In a final effort to improve the results, we can add a nonlinear logic for predicting results:

  * First, look for a result in the trigram training data
  * If no trigram is found, look for a bigram
  * If no bigram is found, use the word frequency list

The resulting performance:


```r
benchmark(predictFromInts, method='sbo')
```

```
## Overall top-5 score:     3.75 %
## Overall top-1 precision: 1.42 %
## Overall top-3 precision: 4.26 %
## Overall top-5 precision: 5.36 %
## Average runtime:         934.20 msec
## Number of predictions:   634
## Total memory used:       4.40 MB
## 
## Dataset details
##  Dataset "data" (51 lines, 838 words, hash c1bb1c56b0c4a151f92ab57279c930a21db643389b99485dccc15caec7daa9ff)
##   Score: 3.75 %, Top-1 precision: 1.42 %, Top-3 precision: 4.26 %, Top-5 precision: 5.36 %
```

Unfortunately, it doesn't look like this method is working either.  The best explanation I have is sparsity, so that's what I'll have to try and address next!

### References

