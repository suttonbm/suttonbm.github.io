---
title: "Coursera Capstone - Week 1"
date: 2016-06-29
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
  Sampling Data from Corpora
---



The task for week 1 of the capstone is to take on cleanup and preparation for analysis of the Swiftkey corpora.

There are two primary outcomes of cleaning the data which need to be addressed:

 * Tokenize the input into relevant predictors (e.g. words, punctuation)
 * Filter profanity so I don't predict it

I'll tackle the tasks above in a [later post]({{ base.url }}/2016/06/tokenize_clean_data/). Today, I'm going to talk about sampling data from the corpora to speed up development of algorithms on the data.

The data for this project are located at: [Dataset](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip)

### Data Sampling

The data for this project are fairly large:


```r
data.blog.path <- "data/en_US.blogs.txt"
data.news.path <- "data/en_US.news.txt"
data.twit.path <- "data/en_US.twitter.txt"

paste("The blog corpus is", file.size(data.blog.path), "Bytes")
```

```
## [1] "The blog corpus is 210160014 Bytes"
```

```r
paste("The news corpus is", file.size(data.news.path), "Bytes")
```

```
## [1] "The news corpus is 205811889 Bytes"
```

```r
paste("The twitter corpus is", file.size(data.twit.path), "Bytes")
```

```
## [1] "The twitter corpus is 167105338 Bytes"
```

For this reason, I'm going to develop my data cleaning algorithms on a subset of the data. Without knowing the contents of these files, the best way to generate an unbiased subset of the data is to randomly sample a certain percentage of lines. The `R.utils` package provides a handy utility for determining the number of lines in a file:


```r
library(R.utils)

data.blog <- file(data.blog.path, open="rb")
data.news <- file(data.news.path, open="rb")
data.twit <- file(data.twit.path, open="rb")

blog.nLines <- countLines(data.blog) #899288 Lines
news.nLines <- countLines(data.news) #1010242 Lines
twit.nLines <- countLines(data.twit) #2360148 Lines

paste("There are", blog.nLines, "lines in the Blog corpus.")
```

```
## [1] "There are 899288 lines in the Blog corpus."
```

```r
paste("There are", news.nLines, "lines in the News corpus.")
```

```
## [1] "There are 1010242 lines in the News corpus."
```

```r
paste("There are", twit.nLines, "lines in the Twitter corpus.")
```

```
## [1] "There are 2360148 lines in the Twitter corpus."
```

So we have a huge number of lines in both data files.  While I could arbitrarily pick a certain number, let's say 1000 lines, from each file, this may not accurately represent the statistics of the overall corpora.  The data will be most accurately represented with a fixed percentage of randomly selected lines chosen from each file.  We can perform this sampling by running a bernoulli trial on each line of the file, where a success is a sampled line.  The target will be ~5000 lines from the Blog corpus.


```r
# Calculate the proportion of lines to select from the blog corpus to yield
# approximately 5000 lines
p.sample <- 5000 / data.blog.nLines

# Set seed and generate a vector of bernoulli trials for each corpus
set.seed(12345)
blog.sampleLines <- rbinom(blog.nLines, 1, p.sample)
news.sampleLines <- rbinom(news.nLines, 1, p.sample)
twit.sampleLines <- rbinom(twit.nLines, 1, p.sample)

# Reset file pointer for each text file
seek(data.blog, 0)
seek(data.news, 0)
seek(data.twit, 0)

# This function will sample lines as defined by `sampleLines`
sampleData <- function(f, sampleLines) {
  data <- c()
  for (k in sampleLines) {
    line <- readLines(f, 1)
    if (k) {
      data <- c(data, line)
    }
  }
  return(data)
}

# Apply function to three corpora
blog.sample <- sampleData(data.blog, blog.sampleLines)
news.sample <- sampleData(data.news, news.sampleLines)
twit.sample <- sampleData(data.twit, twit.sampleLines)

# Save sampled data to file(s)
writeLines(c(blog.sample,
             news.sample,
             twit.sample), "data/en-US.all.sampled.txt")
writeLines(blog.sample, "data/en-US.blogs.sampled.txt")
writeLines(news.sample, "data/en-US.news.sampled.txt")
writeLines(twit.sample, "data/en-US.twitter.sampled.txt")
```



We now have a single dataset, `data`, which contains 0.11% of the lines from all three corpora.  This new, sampled dataset is what we'll use to develop algorithms for cleaning and tokenizing data.

##### Update:

I extended my analysis with a more thorough investigation into the trade-offs associated with using sampled data in [a new post]({{ base.url }}/2016/07/nlp_sampling_updated/)

### References
<p><a id='bib-JSSv025i05'></a><a href="#cite-JSSv025i05">[1]</a><cite>
I. Feinerer, K. Hornik and D. Meyer.
&ldquo;Text Mining Infrastructure in R&rdquo;.
In: <em>Journal of Statistical Software</em> 25.1 (2008), pp. 1&ndash;54.
ISSN: 1548-7660.
DOI: <a href="http://dx.doi.org/10.18637/jss.v025.i05">10.18637/jss.v025.i05</a>.
URL: <a href="https://www.jstatsoft.org/index.php/jss/article/view/v025i05">https://www.jstatsoft.org/index.php/jss/article/view/v025i05</a>.</cite></p>
