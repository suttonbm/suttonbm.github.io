---
title: "Coursera Capstone - Week 2"
date: 2016-07-13
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
  Impact of Sampling Corpora on Available Vocabulary
---



Although I already completed the [sampling data]({{ base.url }}/2016/06/sampling_data/) task, I started thinking about the impact of sampling from the corpus.  In theory, a random subsample should reflect the distribution of the population, but I'm curious what that means for a text corpus.

In this post, I'll investigate this impact in detail.

The data for this project are located at: [Dataset](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip)

### Sampled Data vs. Full Corpus

When I think about measuring the impact of sampling data from the text corpus, the following questions come to mind:

  * What total percentage of terms are captured in the sample data vs the corpus?
  * Are missing terms high or low predictive value?
  * What does the distribution of missing terms look like in the corpus? The top 50 words? The bottom 50?

I'll work with the blog data to investigate.

#### Percentage of Terms in Sample Distribution

Let's take a look at the first question posed above: what percentage of terms are captured in a sample of a text corpus?  I can expand this into a few different questions in order to explore the impact of sampling:

  * Given a text corpus, if N-Gram features are generated for N=(1,2,3), how does the total number of features change for random subsamples of the corpus?
  * How does the question above change for the most frequent terms?
  * How about the least frequent terms?

I've pre-generated summary data to answer the questions above, and loaded them into a variable `TokensVsSize.df`.  [Source](https://github.com/suttonbm/datasciencecoursera_Capstone/blob/master/script/TokensVsSizeData.R)



The generated data is not in the ideal shape for plotting, so we'll do some quick data manipulation:


```r
words <- TokensVsSize.df[,c("words.100", "words.top.99", "words.top.90",
                            "words.top.50", "words.bot.99", "words.bot.90",
                            "size", "p")]
names(words) <- c("all","top99","top90","top50","bot99","bot90","size","p")
words$ngram <- "word"
bigrams <- TokensVsSize.df[,c("bigrams.100", "bigrams.top.99",
                              "bigrams.top.90", "bigrams.top.50",
                              "bigrams.bot.99", "bigrams.bot.90",
                              "size", "p")]
names(bigrams) <- c("all","top99","top90","top50","bot99","bot90","size","p")
bigrams$ngram <- "bigram"
trigrams <- TokensVsSize.df[,c("trigrams.100", "trigrams.top.99",
                               "trigrams.top.90", "trigrams.top.50",
                               "trigrams.bot.99", "trigrams.bot.90",
                               "size", "p")]
names(trigrams) <- c("all","top99","top90","top50","bot99","bot90","size","p")
trigrams$ngram <- "trigram"

tvs.df <- rbind(words, bigrams, trigrams)
```

Now let's use this data to generate some plots and try to answer our questions:


```r
require(ggplot2)

ggplot(data=tvs.df, aes(x = size, y = all, color = ngram)) +
  geom_point() + 
  ggtitle("Total Number of Features") +
  xlab("Corpus Size (Bytes)") + 
  ylab("Number of Features")
```

![center](http://i.imgur.com/Yp9W9im.png)

An interesting observation can be made from this plot - it appears that the number of unique words increases by a type of logarithmic function, but N-grams approach linear growth with the size of a corpus.  The scales make it hard to interpret, so we can normalize:


```r
normalizeData <- function(df, col) {
  allRows <- df[, col]
  inWords <- df$ngram == "word"
  inBigram <- df$ngram == "bigram"
  inTrigram <- df$ngram == "trigram"
  
  allRows[inWords] <- allRows[inWords] / max(allRows[inWords])
  allRows[inBigram] <- allRows[inBigram] / max(allRows[inBigram])
  allRows[inTrigram] <- allRows[inTrigram] / max(allRows[inTrigram])
  
  df[,paste0(col,".norm")] <- allRows
  df
}

tvs.df <- normalizeData(tvs.df, "all")

ggplot(data=tvs.df, aes(x = size, y = all.norm, color = ngram)) +
  geom_point() + 
  ggtitle("Total Number of Features") +
  xlab("Corpus Size (Bytes)") + 
  ylab("Number of Features") +
  stat_function(fun = function(x) { x/max(tvs.df$size) }, colour = "black")
```

![center](http://i.imgur.com/v348FQf.png)

Let's take a look at whether this behavior changes if we only include the top 90% of most frequently used terms:


```r
tvs.df <- normalizeData(tvs.df, "top90")
ggplot(data=tvs.df, aes(x = size, y = top90.norm, color = ngram)) +
  geom_point() +
  ggtitle("Top 90% of Features") +
  xlab("Corpus Size (Bytes)") +
  ylab("Number of Features") +
  stat_function(fun = function(x) { x/max(tvs.df$size) }, colour = "black")
```

![center](http://i.imgur.com/oe1aRvn.png)

Or top 50%:


```r
tvs.df <- normalizeData(tvs.df, "top50")
ggplot(data=tvs.df, aes(x = size, y = top50.norm, color = ngram)) +
  geom_point() +
  ggtitle("Top 50% of Features") +
  xlab("Corpus Size (Bytes)") +
  ylab("Number of Features") +
  stat_function(fun = function(x) { x/max(tvs.df$size) }, colour = "black")
```

![center](http://i.imgur.com/9DQSH0t.png)

Interestingly, trimming the tail, or low frequency features, appears to exaggerate the trend between words and N-grams. We can see especially when looking at the top 50% most frequent terms that increasing corpus size has almost no impact on the number of actual words.  However, there is still a strongly linear relationship when taking combinations of words into account.  Bigrams seem to increase logarithmically with the corpus size, while trigrams appear to increase nearly linearly.

It would be fascinating to run this experiment out to even larger corpora just to see whether 3-grams or larger continue to hold a linear relationship.  I would expect that at some point the frequency of new phrases becomes scarce and the logarithmic relationship would once again arise.

Finally, what happens if we only look at the bottom 90%.  In other words, let's throw out the most frequent terms and see what happens:


```r
tvs.df <- normalizeData(tvs.df, "bot90")
ggplot(data=tvs.df, aes(x = size, y = bot90.norm, color = ngram)) +
  geom_point() +
  ggtitle("Bottom 90% of Features") +
  xlab("Corpus Size (Bytes)") +
  ylab("Number of Features") +
  stat_function(fun = function(x) { x/max(tvs.df$size) }, colour = "black")
```

![center](http://i.imgur.com/FykPZp2.png)

The logarithmic signal once again shows itself, but it is far less dramatically different comparing words to N-grams. This result is a pretty strong contrast to the top 90% figure above.

One final thought - I've attributed these plots to a logarithmic relationship, but I have to wonder if that is also inappropriate.  I would hypothesize that the number of words or N-grams in a corpus would increase asymptotically.  Clearly there are not an infinite number of words in any language, and therefore an unbounded function such as the logarithm would not be seem to make sense.

**Update:**
As it turns out (not surprisingly), this has been studied in the past, and it follows a distribution called a "Zipf" distribution.
[1] "(Powers, 1998)"

#### Predictive Value of Missing Terms

The second question I posed at the start of this post was whether terms missing from random subsamples of a corpus tended towards high or low predictive value terms. To reduce computation time, let's compare two subsets of the blogs corpus, selected by bernoulli trial with p=0.001 and p=0.01.  I've loaded the relevant data into variables `blogs.001` and `blogs.010`, respectively.



I've also created a helper function to pull out features of the larger corpus that do not exist in the subset, `getDeltaFeatures()`.  [Source](https://github.com/suttonbm/datasciencecoursera_Capstone/blob/master/script/getDeltaFeatures.R)



```r
delta.df <- getDeltaFeatures(blogs.01, blogs.001)
```

Let's take a quick look at the distribution of terms (normalized to the larger corpus):


```r
delta.df$count.norm <- delta.df$count / max(blogs.01$count)
qplot(seq_along(delta.df$count.norm), delta.df$count.norm)
```

![center](http://i.imgur.com/bq93Rkf.png)

It would appear that the terms missing from the subset are primarily low-frequency terms which may provide good predictive value.  Terms used infrequently in a corpus may mean that they can predict other words used in conjunction with high accuracy compared to terms appearing with very high frequency.

Let's take a look at exactly where these terms fall in the overall corpus:


```r
blogs.01$delta <- blogs.01$ngram %in% delta.df$ngram
blogs.01$n <- seq_along(blogs.01$ngram)

ggplot(data=blogs.01, aes(x=n, y=count, color=delta)) +
  geom_bar(stat="identity") +
  scale_y_log10() +
  xlim(0, 10000) +
  ggtitle("Distribution of Sampled Features (N=1)")
```

![center](http://i.imgur.com/XjiBYFT.png)

Interestingly, but not surprisingly, it is not only the low-frequency terms that are missed with a subset of the data.  Given that the data was sampled using a uniform distribution (bernoulli trial), it is expected that higher frequency terms would be sampled and lower frequency terms might be missed.

Let's look at the same plot for bigram and trigram features:



```r
delta.df.bi <- getDeltaFeatures(blogs.01.bi, blogs.001.bi)

blogs.01.bi$delta <- blogs.01.bi$ngram %in% delta.df.bi$ngram
blogs.01.bi$n <- seq_along(blogs.01.bi$ngram)

ggplot(data=blogs.01.bi, aes(x=n, y=count, color=delta)) +
  geom_bar(stat="identity") +
  scale_y_log10() +
  xlim(0, 30000) +
  ggtitle("Distribution of Sampled Features (N=2)")
```

![center](http://i.imgur.com/5jWAQMn.png)


```r
delta.df.tri <- getDeltaFeatures(blogs.01.tri, blogs.001.tri)

blogs.01.tri$delta <- blogs.01.tri$ngram %in% delta.df.tri$ngram
blogs.01.tri$n <- seq_along(blogs.01.tri$ngram)

ggplot(data=blogs.01.tri, aes(x=n, y=count, color=delta)) +
  geom_bar(stat="identity") +
  scale_y_log10() +
  xlim(0,20000) +
  ggtitle("Distribution of Sampled Features (N=3)")
```

![center](http://i.imgur.com/JNChm2Y.png)

It appears that the distribution of missing terms within the corpus does not change significantly for bigram or trigram features.

### References
<p><a id='bib-W98-1218'></a><a href="#cite-W98-1218">[1]</a><cite>
D. M. Powers.
&ldquo;Applications and Explanations of Zipf's Law&rdquo;.
In: <em>New Methods in Language Processing and Computational Natural Language Learning</em> (1998), pp. 151&ndash;160.
URL: <a href="http://aclweb.org/anthology/W98-1218">http://aclweb.org/anthology/W98-1218</a>.</cite></p>
