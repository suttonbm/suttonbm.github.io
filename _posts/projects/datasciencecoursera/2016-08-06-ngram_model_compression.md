---
title: "Coursera Capstone - Week 2"
date: 2016-08-06
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
  Compressing n-gram models for efficient storage
---



There are two tasks for week 2 of the SwiftKey Natural Language Processing Capstone for the Coursera Data Science specialization:

  * Exploratory Data Analysis
  * Simple Language Modeling

In this post, I'm going to discuss one strategy for compressing n-gram model data for disk and memory efficiency.

The data for this project are located at: [Dataset](https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/Coursera-SwiftKey.zip)

### Introduction

I've been reading over some final reports from previous students in the NLP Capstone course, and it seems like a huge challenge for many is memory utilization.  Memory management is a problem in the NLP project for two reasons:

  * R can only work within memory, and the corpora are very large
  * There is a maximum amount of memory available for shinyapps.io projects

The former is more of challenge for pre-processing, and is most readily addressed by developing algorithms first on a subset of data, then processing the whole corpora in chunks.  The latter, however, has fewer obvious solutions.  A full n-gram model of the corpus is huge, and in order to perform prediction, all the data needs to be available to R.  The solution I propose uses two complementary approaches.  First, throw out any data that is not needed, and second, compress the data.  Finally, to truly minimize the amount of memory used by the app, we can also choose to store the n-gram model in a database such as SQLite, which makes the data available without storing the full model in memory.

### Throwing out Unneeded N-Grams

For the NLP Capstone project, the ultimate goal is to predict a set of five (5) words which might follow a sentence input by the user.  However, many of the most frequent n-grams (N<4) appear many more times.  For example, the corpus might have the following sentences:

  * hello how are you? - appears 50 times
  * hello how are my cats? - appears 20 times
  * hello how are the cars? - appears 12 times
  * hello how are his dogs? - appears 6 times
  * hello how are her geckos? - appears 4 times
  * hello how are we still talking? - appears 2 times
  * hello how are football cheddar sticks? - appears 1 time

If we were to generate a set of n-grams from the data above, we would have seven outcomes based on the predictor `hello how are`.  Because the end product will only provide five suggestions, we can simply throw out infrequent n-grams until we are left with only five:

  * ... you?
  * ... my cats?
  * ... the cars?
  * ... his dogs?
  * ... her geckos?

By doing this, we can eliminate many unnecessary components of the model, and in doing so, reduce the disk or memory space required.

### Compressing the Data

As far as a computer is concerned, words are just chunks of numbers floating in cyberspace.  Most character encoding schemes store each character as an eight-bit integer.  This means that every character stored in a file or database costs eight bits - a pretty big number.  The average word length in english is ~5 letters.  Let's also say there are 50,000 words in the english language.  The total memory needed to store this estimate of the language would be:

```
8 * 5 * 50000 = 2e6 bits
```

If we were to generate a full-factorial bigram model of the language, multiply that by four.  The numbers get huge pretty fast.

Now, what if we could represent each word as an arbitrary number.  We would need a unique number for each word, requiring 16 bits (2^16 = 65536).  However, this would lead to:

```
16 * 50000 = 8e5 bits
```

Representing words as numbers yields a 60% reduction in size!

The next question - if words are stored as arbitrary numbers, how do you get the words back?  The answer is, you need a dictionary.  For a unigram model, there is no net space savings.  However, the real benefit comes from n-gram models.

For plain text trigrams (full factorial):

```
8 * 5 * 50000 * 9 = 18e6 bits
```

For full factorial trigrams stored as 16 bit integers plus a dictionary:

```
16 * 50000 * 9 + 16 * 50000 + 8 * 5 * 50000 = 10e6
```

Almost a 50% reduction in size.  Again, combined with a file-system back database, most of this data is not needed in memory at runtime.  Approximately 8e6 bits are stored in disk, and 2e6 are required in memory - a 9x reduction in memory cost, at the cost of modestly increased search time as the SQL query is run against the database.

### Conclusion

By utilizing a word dictionary and SQLite database for the markov model, we can achieve a compression in total size of the data paired with a significant decrease in RAM requirement while running the model.



