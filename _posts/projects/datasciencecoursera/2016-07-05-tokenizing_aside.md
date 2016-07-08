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

![center](http://i.imgur.com/GsiPXaA.png)![center](http://i.imgur.com/xpAHyqe.png)

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

![center](http://i.imgur.com/Oatxy4p.png)

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

![center](http://i.imgur.com/uvrsJoP.png)

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

# Evaluate 2-grams
qeda.2.df <- doEvaluate.qeda('qeda.2-gram', n=2)

# Evaluate 3-grams
qeda.3.df <- doEvaluate.qeda('qeda.3-gram', n=3)
```

![center](http://i.imgur.com/3qtZdZ2.png)

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

[3](https://rpubs.com/erodriguez/nlpquanteda)
[4](http://stackoverflow.com/questions/21921422/row-sum-for-large-term-document-matrix-simple-triplet-matrix-tm-package)


