---
title: "Coursera Capstone - Week 2"
date: 2016-07-08
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
  Aside: Efficient tokenizing strategy for NLP in R
---



While working on the exploratory data analysis of the Swiftkey NLP project, I quickly came to the realization that the HUGE corpus provided (see [HC Corpora](http://www.corpora.heliohost.org/)) poses a significant challenge when it comes to tokenizing data on a home laptop or desktop computer. Reading the raw text files into memory can be a limitation, and generating N-gram tokens can be computationally intensive (read: many hours of computation time). For this reason, I'm going to dedicate an entire post to summarizing my investigation into the various options for tokenizing data in R to find the most effective methods.

### Methods to Consider

There are many different tools in existence today which allow a user to generate tokenized N-Gram models of text corpora. A short list (I'm sure this is far from comprehensive) follows:

  * Base [`tm`](https://cran.r-project.org/web/packages/tm/index.html) package (basic term-document matrix N=1 only.)
  * The base [`NLP`](https://cran.r-project.org/web/packages/NLP/index.html) package
  * The [`ngram`](https://cran.r-project.org/web/packages/ngram/) package (just for tokenizing)
  * [`openNLP`](https://cran.r-project.org/web/packages/openNLP/index.html)
  * [`RWeka`](https://cran.r-project.org/web/packages/RWeka/index.html)
  * [`quanteda`](https://cran.r-project.org/web/packages/quanteda/index.html)

There are many other options available outside of the R processing environment, such as:

  * Stanford's [OpenNLP](http://stanfordnlp.github.io/CoreNLP/#about) Library (Java)
  * The [NLTK Toolkit](http://www.nltk.org) Library (Python)
  * The [textblob](https://pypi.python.org/pypi/textblob) Library (Python)

I'm going to take a look at a few of these options to see how they perform relative to each other.  Also note that I've left out some code chunks to keep the length reasonable. The source is available with full code on [my Github](https://github.com/suttonbm/datasciencecoursera_Capstone/blob/master/2016-07-05-tokenizing_aside.rmd).



### Methodology

This study is focused primarily on performance of various tokenization algorithms and packages available.  Processing time will be the dependent variable, measured using the `system.time()` function in R.  I'll be taking measurements of tokenize time for five different files ranging in size from 14KB to 10MB to capture any nonlinearity in scaling for the various options as well.  Wherever possible I'll be taking advantage of parallel processing via the `doParallel` package using the generic function below:


```r
library(doParallel)

parallelTask <- function(task, ...) {
  ncores <- detectCores() - 1
  options(mc.cores = ncores)
  cl <- makeCluster(ncores)
  registerDoParallel(cl)
  r <- task(...)
  stopCluster(cl)
  r
}
```

Preprocessing of the data will be limited to removing punctuation, numbers, excess whitespace, and conversion to lowercase.  All preprocessing has been completed using the `tm` package.

The measurement will be executed using a second generic function, defined below:


```r
doEvaluate <- function(method.name, tokenFn, ...) {
  times <- list()
  for (id in ids) {
    t <- system.time({
      parallelTask(tokenFn, corpora[[id]], ...)
    })[['elapsed']]
    times[[id]] <- t
  }
  
  results <- data.frame(method = method.name,
                        file.size = unlist(file.sizes, use.names=F),
                        file.lines = unlist(nLines, use.names=F),
                        perf = unlist(times, use.names=F))
  return(results)
}
```

### Base TM Package Performance

The base `tm` package implements three tokenizer options.  I'll explain the functionality behind these tokenizers below.  Take note that all three tokenizers provided by the `tm` package are for single words.  No N-Gram capability exists in the base `tm` package (but a custom function can make it work).

  * `words` (from NLP package)
  * `scan` (from base R)
  * [MC Tokenizer](http://www.cs.utexas.edu/users/dml/software/mc/)

The `words` tokenizer is the default in the `tm` package: If a user calls `TermDocumentMatrix` or `DocumentTermMatrix` without specifying a specific tokenizer to use, the tm package will use this option.

A tokenizer in the `tm` package is applied on a line-by-line basis to the text corpus via `mclapply`.  In theory, this may allow `tm` to apply the tokenizer in parallel if multiple cores are available.  A custom tokenizer should take a string as input and return a character vector of features.  One point to take note of is that `tm` does not make any assumptions about sentence structure during tokenization.  If there are multiple sentences on a single line, N-gram tokens may be generated with the form of `<end sentence>. <start sentence>`.  It is left to the user to determine if this will negatively impact the NLP task to be undertaken.

#### Words Tokenizer

The words tokenizer makes use of the `words` function from the `NLP` package.  As far as I can tell, this is implemented as a simple whitespace tokenizer in R. Furthermore, the splitting functionality is implemented as a regEx search function in R.  I'd hypothesize this is not a computationally efficient implementation.  As mentioned above, this option is the default for `TermDocumentMatrix` and `DocumentTermMatrix`

#### Scan Tokenizer

The scan tokenizer uses the `scan` function from base R, and reads in the data character-by-character.  The returned vector generates tokens based on this (not words).  For my purposes, this will not work; I need to build word features.

The R code required to use this option is as follows:

```r
tdm <- tm::TermDocumentMatrix(corpus, control=list(tokenize=tm::scan_tokenizer))
```

#### MC Tokenizer

The MC tokenizer is a slightly modified version of the words tokenizer, taken from the [MC Toolkit](http://www.cs.utexas.edu/users/dml/software/mc/), which extracts emal addresses or URLs from the corpus using regular expressions.  This function, unlike the MC Toolkit, is written in R, and will not have the same high performance of compiled C++ code.

R Code:

```r
tdm <- tm::TermDocumentMatrix(corpus, control=list(tokenize=tm::MC_tokenizer))
```

#### Package Performance


```r
# Test the `words` tokenizer
words.df <- doEvaluate('tm.words', tm::TermDocumentMatrix)

# Test the `MC_tokenizer`
mc.df <- doEvaluate('tm.mc', tm::TermDocumentMatrix, control=list(tokenize=tm::MC_tokenizer))
```

![center]({{ site.url }}http://i.imgur.com/GsiPXaA.png)![center]({{ site.url }}http://i.imgur.com/xpAHyqe.png)

Based on the plots above, we can draw a few conclusions:

  * Both the `MC` and `words` tokenizers appear to scale linearly with number of lines
  * Neither tokenizer correlates strongly with file size
  * The `words` tokenizer operates ~3x faster than the `MC` tokenizer for a given file.  This is likely due to the email/URL regular expression checking in the `MC` tokenizer

### TM + NLP Performance

The NLP package enables us to generate arbitrary N-Grams using the tm package by specifying a custom tokenize argument.  First we need to specify a couple functions.  The following function definitions will allow us to generate bigram and trigram (N=2 and 3, respectively) features from the dataset:


```r
ngram.nlp <- function(x, n=1) {
  unlist(lapply(NLP::ngrams(NLP::words(x), n), paste, collapse = " "), use.names = FALSE)
}

bigram.nlp <- function(x) {
  ngram.nlp(x, n=2)
}

trigram.nlp <- function(x) {
  ngram.nlp(x, n=3)
}
```

Now we can evaluate term-document matrix generation as follows:


```r
# Evaluate bigram matrix generation
nlp.2.df <- doEvaluate('nlp.2-gram', tm::TermDocumentMatrix, control=list(tokenize=bigram.nlp))

# Evaluate trigram matrix generation
nlp.3.df <- doEvaluate('nlp.3-gram', tm::TermDocumentMatrix, control=list(tokenize=bigram.nlp))
```

![center]({{ site.url }}http://i.imgur.com/Oatxy4p.png)

The `NLP::ngrams` function operates slightly slower than the `words` method above, but still faster than the `MC` method.  The increase in time compared to `words` is not surprising due to the extra combinatorics of generating N-grams versus splitting on whitespace.  One interesting observation is that linear correlation to number of lines is less distinct.  I would hypothesize that the result depends on number of words per line, but I didn't gather the necessary data to confirm the result.  Another interesting observation is that generating 3-grams confers a much smaller penalty over 2-grams than does generating 2-grams over whitespace splitting.

### RWeka Performance

Similar to the NLP package, the RWeka package provides a number of external tokenizer functions which perform a similar function to the NLP package above.  In this case, however, the tokenizing occurs in Java, outside of the R environment.  We can define bigram and trigram generating functions as follows:


```
## [1] 0
```


```r
ngram.rweka <- function(x, n=1) {
  RWeka::NGramTokenizer(x, RWeka::Weka_control(min = n, max = n))
}

unigram.rweka <- function(x) {
  ngram.rweka(x, n=1)
}

bigram.rweka <- function(x) {
  ngram.rweka(x, n=2)
}

trigram.rweka <- function(x) {
  ngram.rweka(x, n=3)
}
```

And then evaluate the performance of those functions below:


```r
# Evaluate 1-grams
rweka.1.df <- doEvaluate('RWeka.1-gram', tm::TermDocumentMatrix, control=list(tokenize=unigram.rweka))

# Evaluate 2-grams
rweka.2.df <- doEvaluate('RWeka.2-gram', tm::TermDocumentMatrix, control=list(tokenize=bigram.rweka))

# Evaluate 3-grams
rweka.3.df <- doEvaluate('RWeka.3-gram', tm::TermDocumentMatrix, control=list(tokenize=trigram.rweka))
```

![center]({{ site.url }}http://i.imgur.com/uvrsJoP.png)

We can see from the plots above that the RWeka tokenizer runs significantly slower than both the `words` tokenizer and the `NLP::ngrams` tokenizers above.  I don't fully understand what's going on under the hood of the RWeka package or the Weka tool in Java, so I'd have to theorize that there may be something going on algorithmically to cause such a slowdown.

### Quanteda Performance

The final package I'll evaluate is the `quanteda` package. This package works independently of the `tm` package, and requires a different type of input to tokenize the data. Luckily, the package provides a constructor for the `quanteda::corpus` class which takes a `tm::VCorpus` as an input.  In order to eliminate any timing bias due to this translation, we'll have to update the `parallelTask()` and `doEvaluate()` functions, as well as the underlying data.  I've left out the full code for brevity, but the source can be found on [Github](#).

The creation of a `quanteda::corpus` can be handled with the following R code:


```r
tm.corpus <- tm::VCorpus(tm::VectorSource(readLines("textfile.txt")))
qeda.corpus <- quanteda::corpus(tm.corpus)
```

One of the cool perks of the `quanteda` package is its ability to perform sentence recognition prior to tokenization.  I am not making use of this feature in the evaluation to try and reduce dimensionality of the problem.  However, another code snippet follows which defines a function to pre-split the data into sentences:


```r
makeSentences <- function(input) {
  out <- quanteda::tokenize(input,
                            what="sentence",
                            removeNumbers = TRUE,
                            removePunct = TRUE,
                            removeSeparators = TRUE,
                            removeTwitter = TRUE)
  unlist(lapply(out, function(x) paste(quanteda::toLower(x))))
}
```



#### Package Performance

We can run an evaluation of the `quanteda` package as follows:


```r
qeda.dfm <- function(corpus, n=1) {
  tokens <- quanteda::tokenize(what='word', ngrams=n, simplify=TRUE)
  return(quanteda::dfm(tokens))
}

# Evaluate 1-grams
qeda.1.df <- doEvaluate.qeda('qeda.1-gram', n=1)
```

```
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 40,888 documents
##    ... indexing features: 7,816 feature types
##    ... created a 40888 x 7817 sparse dfm
##    ... complete. 
## Elapsed time: 0.39 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 2,415 documents
##    ... indexing features: 1,210 feature types
##    ... created a 2415 x 1211 sparse dfm
##    ... complete. 
## Elapsed time: 0.04 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 29,943 documents
##    ... indexing features: 6,286 feature types
##    ... created a 29943 x 6287 sparse dfm
##    ... complete. 
## Elapsed time: 0.26 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 201,035 documents
##    ... indexing features: 20,862 feature types
##    ... created a 201035 x 20863 sparse dfm
##    ... complete. 
## Elapsed time: 2.17 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 14,359 documents
##    ... indexing features: 4,363 feature types
##    ... created a 14359 x 4364 sparse dfm
##    ... complete. 
## Elapsed time: 0.15 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 150,488 documents
##    ... indexing features: 17,649 feature types
##    ... created a 150488 x 17650 sparse dfm
##    ... complete. 
## Elapsed time: 1.38 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 392,159 documents
##    ... indexing features: 31,035 feature types
##    ... created a 392159 x 31036 sparse dfm
##    ... complete. 
## Elapsed time: 4.31 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 27,683 documents
##    ... indexing features: 6,926 feature types
##    ... created a 27683 x 6927 sparse dfm
##    ... complete. 
## Elapsed time: 0.25 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 299,020 documents
##    ... indexing features: 26,830 feature types
##    ... created a 299020 x 26831 sparse dfm
##    ... complete. 
## Elapsed time: 3.12 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 1,950,417 documents
##    ... indexing features: 76,759 feature types
##    ... created a 1950417 x 76760 sparse dfm
##    ... complete. 
## Elapsed time: 25.96 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 132,228 documents
##    ... indexing features: 18,333 feature types
##    ... created a 132228 x 18334 sparse dfm
##    ... complete. 
## Elapsed time: 1.13 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 1,493,181 documents
##    ... indexing features: 71,248 feature types
##    ... created a 1493181 x 71249 sparse dfm
##    ... complete. 
## Elapsed time: 17.77 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 262,628 documents
##    ... indexing features: 27,201 feature types
##    ... created a 262628 x 27202 sparse dfm
##    ... complete. 
## Elapsed time: 2.77 seconds.
```

```r
# Evaluate 2-grams
qeda.2.df <- doEvaluate.qeda('qeda.2-gram', n=2)
```

```
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 39,956 documents
##    ... indexing features: 27,476 feature types
##    ... created a 39956 x 27477 sparse dfm
##    ... complete. 
## Elapsed time: 0.38 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 2,337 documents
##    ... indexing features: 2,132 feature types
##    ... created a 2337 x 2133 sparse dfm
##    ... complete. 
## Elapsed time: 0.03 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 27,527 documents
##    ... indexing features: 20,509 feature types
##    ... created a 27527 x 20510 sparse dfm
##    ... complete. 
## Elapsed time: 0.26 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 196,461 documents
##    ... indexing features: 108,186 feature types
##    ... created a 196461 x 108187 sparse dfm
##    ... complete. 
## Elapsed time: 2.3 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 13,946 documents
##    ... indexing features: 11,573 feature types
##    ... created a 13946 x 11574 sparse dfm
##    ... complete. 
## Elapsed time: 0.12 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 138,441 documents
##    ... indexing features: 82,573 feature types
##    ... created a 138441 x 82574 sparse dfm
##    ... complete. 
## Elapsed time: 1.69 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 383,152 documents
##    ... indexing features: 189,075 feature types
##    ... created a 383152 x 189076 sparse dfm
##    ... complete. 
## Elapsed time: 4.42 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 26,875 documents
##    ... indexing features: 21,105 feature types
##    ... created a 26875 x 21106 sparse dfm
##    ... complete. 
## Elapsed time: 0.25 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 275,206 documents
##    ... indexing features: 146,612 feature types
##    ... created a 275206 x 146613 sparse dfm
##    ... complete. 
## Elapsed time: 3.5 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 1,905,243 documents
##    ... indexing features: 683,951 feature types
##    ... created a 1905243 x 683952 sparse dfm
##    ... complete. 
## Elapsed time: 29.03 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 128,389 documents
##    ... indexing features: 84,697 feature types
##    ... created a 128389 x 84698 sparse dfm
##    ... complete. 
## Elapsed time: 1.13 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 1,374,509 documents
##    ... indexing features: 540,160 feature types
##    ... created a 1374509 x 540161 sparse dfm
##    ... complete. 
## Elapsed time: 18.5 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 254,863 documents
##    ... indexing features: 151,667 feature types
##    ... created a 254863 x 151668 sparse dfm
##    ... complete. 
## Elapsed time: 2.78 seconds.
```

```r
# Evaluate 3-grams
qeda.3.df <- doEvaluate.qeda('qeda.3-gram', n=3)
```

```
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 39,048 documents
##    ... indexing features: 35,989 feature types
##    ... created a 39048 x 35990 sparse dfm
##    ... complete. 
## Elapsed time: 0.39 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 2,260 documents
##    ... indexing features: 2,215 feature types
##    ... created a 2260 x 2216 sparse dfm
##    ... complete. 
## Elapsed time: 0.02 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 25,112 documents
##    ... indexing features: 24,124 feature types
##    ... created a 25112 x 24125 sparse dfm
##    ... complete. 
## Elapsed time: 0.25 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 191,981 documents
##    ... indexing features: 167,578 feature types
##    ... created a 191981 x 167579 sparse dfm
##    ... complete. 
## Elapsed time: 1.99 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 13,535 documents
##    ... indexing features: 13,182 feature types
##    ... created a 13535 x 13183 sparse dfm
##    ... complete. 
## Elapsed time: 0.15 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 126,403 documents
##    ... indexing features: 114,459 feature types
##    ... created a 126403 x 114460 sparse dfm
##    ... complete. 
## Elapsed time: 1.29 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 374,329 documents
##    ... indexing features: 314,885 feature types
##    ... created a 374329 x 314886 sparse dfm
##    ... complete. 
## Elapsed time: 4.24 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 26,071 documents
##    ... indexing features: 25,202 feature types
##    ... created a 26071 x 25203 sparse dfm
##    ... complete. 
## Elapsed time: 0.27 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 251,407 documents
##    ... indexing features: 219,322 feature types
##    ... created a 251407 x 219323 sparse dfm
##    ... complete. 
## Elapsed time: 2.91 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 1,860,988 documents
##    ... indexing features: 1,383,713 feature types
##    ... created a 1860988 x 1383714 sparse dfm
##    ... complete. 
## Elapsed time: 25.72 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 124,571 documents
##    ... indexing features: 115,941 feature types
##    ... created a 124571 x 115942 sparse dfm
##    ... complete. 
## Elapsed time: 1.3 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 1,255,898 documents
##    ... indexing features: 970,944 feature types
##    ... created a 1255898 x 970945 sparse dfm
##    ... complete. 
## Elapsed time: 16.44 seconds.
## 
##    ... lowercasing
##    ... tokenizing
##    ... indexing documents: 247,147 documents
##    ... indexing features: 223,755 feature types
##    ... created a 247147 x 223756 sparse dfm
##    ... complete. 
## Elapsed time: 2.91 seconds.
```

![center]({{ site.url }}http://i.imgur.com/3qtZdZ2.png)

While the `quanteda` package does not appear to provide a significant benefit over the base `words` approach, it does appear to provide consistent results regardless of n-gram selection.  Splitting on whitespace takes approximately the same time as generating 2- and 3-gram data.

### Summary



In conclusion, I've studied the processing times for a variety of tokenizing packages and algorithms available in R today. The results show fairly wide variation in performance, with the `RWeka` and `tm::MC_tokenizer` options significantly underperforming the field.  For small datasets, it would appear the tools available in the `tm` and `NLP` packages are the most effective, but for larger datasets or N-gram data with N>1, the `quanteda` package may be the better choice.

### References
<p><a id='bib-JSSv025i05'></a><a href="#cite-JSSv025i05">[1]</a><cite>
I. Feinerer, K. Hornik and D. Meyer.
&ldquo;Text Mining Infrastructure in R&rdquo;.
In: <em>Journal of Statistical Software</em> 25.1 (2008), pp. 1&ndash;54.
ISSN: 1548-7660.
DOI: <a href="http://dx.doi.org/10.18637/jss.v025.i05">10.18637/jss.v025.i05</a>.
URL: <a href="https://www.jstatsoft.org/index.php/jss/article/view/v025i05">https://www.jstatsoft.org/index.php/jss/article/view/v025i05</a>.</cite></p>

<p><a id='bib-CBO9781139058452A007'></a><a href="#cite-CBO9781139058452A007">[2]</a><cite>
A. Rajaraman and J. D. Ullman.
&ldquo;Data Mining&rdquo;.
In: 
<em>Mining of Massive Datasets</em>.
Ed. by C. B. Online.
Cambridge Books Online.
Cambridge University Press, 2011, pp. 1&ndash;17.
ISBN: 9781139058452.
URL: <a href="http://dx.doi.org/10.1017/CBO9781139058452.002">http://dx.doi.org/10.1017/CBO9781139058452.002</a>.</cite></p>

[1](https://rpubs.com/erodriguez/nlpquanteda)
[2](http://stackoverflow.com/questions/21921422/row-sum-for-large-term-document-matrix-simple-triplet-matrix-tm-package)

