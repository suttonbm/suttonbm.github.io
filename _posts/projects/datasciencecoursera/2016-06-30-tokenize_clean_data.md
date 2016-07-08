---
title: "Coursera Capstone - Week 1"
date: 2016-06-30
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
  Cleaning and Tokenizing Data
---



The task for week 1 of the capstone is to take on cleanup and preparation for analysis of the Swiftkey corpora.

There are two primary outcomes of cleaning the data which need to be addressed:

 * Tokenize the input into relevant predictors (e.g. words, punctuation)
 * Filter profanity so I don't predict it

The data for this project are located at: [Dataset](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip)

### Cleaning the Data

I discussed generating a subsample of the text corpora used in the course in an [earlier post]({{ base.url }}/2016/06/sampling_data/). To start out, let's load the sampled dataset that was generated there:


```r
sample.1 <- readLines("data/en_US.blogs.txt.0.005", encoding="UTF-8")
sample.2 <- readLines("data/en_US.news.txt.0.005", encoding="UTF-8")
sample.3 <- readLines("data/en_US.twitter.txt.0.005", encoding="UTF-8")

data.sample <- c(sample.1, sample.2, sample.3)
```

Next, we need to clean up the data. The strict definition above is to eliminate profanity if possible.  However, when doing natural language processing, we also need to consider predictive ability of words and eliminate those with low entropy (stopwords).
[1] "(Rajaraman and Ullman, 2011)"

Both of these activities can be addressed using the `tm` package in R.  First, let's create a corpus.


```r
library(tm)

sample_corpus <- Corpus(VectorSource(data.sample))
iconv(as.character(sample_corpus[[6]]), to="ASCII")
```

```
## [1] "If you are interested in the national private midwifery scene, or trying to locate a midwife outside Victoria, please go to the APMA blog."
```

Using the corpus object within the `tm` package, we can perform some basic operations to clean up the data before splitting into tokens:


```r
# Eliminate punctuation marks
sample_corpus <- tm_map(sample_corpus, removePunctuation)
# Eliminate numbers
sample_corpus <- tm_map(sample_corpus, removeNumbers)
# Convert to lowercase
sample_corpus <- tm_map(sample_corpus, content_transformer(tolower))
```

```
## Error in FUN(content(x), ...): invalid input 'Time to dream bout some crazy ishhh goodnight 💤' in 'utf8towcs'
```

```r
iconv(as.character(sample_corpus[[6]]), to="ASCII")
```

```
## [1] "If you are interested in the national private midwifery scene or trying to locate a midwife outside Victoria please go to the APMA blog"
```

The `tm` package provides a convenient method of removing words from a corpus by using another data source.  For example:


```r
words <- VectorSource(readLines(file("file-with-words-to-remove.txt")))
corpus <- tm_map(corpus, removeWords, words)
```

There is also a built-in function that contains a list of english stopwords, accessed with:


```r
corpus <- tm_map(corpus, removeWords, stopwords("english"))
```

To filter out profanity in the corpus, I forked a [gist](https://gist.github.com/suttonbm/8689df95d7ff4d302d60bcbccb21d19d) that I found on Github and made some formatting modifications to meet my own needs.  I don't know that this list is entirely exhaustive, but it is better than I could have created from scratch.  I won't post the contents in this post (to keep it PG), but I've added a link to the content above for reference.  I can use this file to filter my data:


```r
expletives <- VectorSource(readLines("data/expletives-coursera-swiftkey-nlp"))
sample_corpus <- tm_map(sample_corpus, removeWords, expletives$content)

# And removing stopwords
sample_corpus <- tm_map(sample_corpus, removeWords, stopwords("english"))

# Finally, strip excess whitespace
sample_corpus <- tm_map(sample_corpus, stripWhitespace)

iconv(as.character(sample_corpus[[6]]), to="ASCII")
```

```
## [1] "If interested national private midwifery scene trying locate midwife outside Victoria please go APMA blog"
```

In theory, now the corpus has had all expletives and english stopwords removed. Note how the printed line has changed between raw data import and pre-processing/cleaning.

### Tokenizing the Data

Now that I have a (reasonably) clean dataset, I need to split it into tokens.  In other words, I need to take a vector of *paragraphs* and turn it into a vector of *words*.  The most simplistic method is to split the strings by whitespace:


```r
(sample_line <- strsplit(iconv(as.character(sample_corpus[[6]]), to="ASCII"),
                         "\\s+"))
```

```
## [[1]]
##  [1] "If"         "interested" "national"   "private"    "midwifery" 
##  [6] "scene"      "trying"     "locate"     "midwife"    "outside"   
## [11] "Victoria"   "please"     "go"         "APMA"       "blog"
```

However, this may not be the best method of summarizing the data.  We'll explore this further in the [next post]({{ base_url }}/2016/07/nlp_data_exploration)

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
