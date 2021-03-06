---
title: "Statistical Inference"
date: 2016-04-30T2:29
author: suttonbm
layout: post
categories:
  - projects
tags:
  - coursera
  - data.science
  - R
project: datasciencecoursera
excerpt: >
  Quiz 2
---



# Quiz 2

## Question 1
What is the variance of the distribution of the average an IID draw of $$n$$ observations from a population with mean $$\mu$$ and variance $$\sigma^2$$?

## Solution
For large $$n$$, the distribution of $$S_n$$ (sample variance) approximates a normal distribution with mean $$\mu$$ and variance $$\frac{\sigma^2}{n}$$

## Question 2
Suppose that diastolic blood pressures (DBPs) for men aged 35-44 are normally distributed with a mean of 80 (mm Hg) and a standard deviation of 10. About what is the probability that a random 35-44 year old has a DBP less than 70?

## Solution
Let $$X$$ be DBP. Calculate $$P(X \leq 70)$$ given that $$X \equiv N(80, 10^2)$$

```r
maxDBP <- 70
mean <- 80
sigma <- 10
round(pnorm(maxDBP, mean=mean, sd=sigma) * 100)
```

```
## [1] 16
```

## Question 3
Brain volume for adult women is normally distributed with a mean of about 1,100 cc for women with a standard deviation of 75 cc. What brain volume represents the 95th percentile?

## Solution
Let $$B$$ be brain volume.  Calculate $$b$$ s.t. $$P(B \leq b) = 0.95$$.

```r
percentile <- 0.95
mean <- 1100
sigma <- 75
round(qnorm(percentile, mean=mean, sd=sigma))
```

```
## [1] 1223
```

## Question 4
Refer to the previous question. Brain volume for adult women is about 1,100 cc for women with a standard deviation of 75 cc. Consider the sample mean of 100 random adult women from this population. What is the 95th percentile of the distribution of that sample mean?

## Solution
Let $$\bar{X}$$ be the average sample mean for 100 randomly sampled women.  The standard error is given by $$SE_{\bar{X}} = \frac{\sigma}{\sqrt{n}}$$

```r
percentile <- 0.95
n <- 100
mean <- 1100
sigma <- 75
SE <- sigma/sqrt(n)
round(qnorm(percentile, mean=mean, sd=SE))
```

```
## [1] 1112
```

## Question 5
You flip a fair coin 5 times, about what's the probability of getting 4 or 5 heads?

## Solution
Let $$C$$ be the outcome of this experiment.  $$C \equiv binom(5, 0.5)$$.

```r
trials <- 5
p_success <- 0.5
quantile <- 3
round((1-pbinom(quantile, size=trials, prob=p_success)) * 100)
```

```
## [1] 19
```

## Question 6
The respiratory disturbance index (RDI), a measure of sleep disturbance, for a specific population has a mean of 15 (sleep events per hour) and a standard deviation of 10. They are not normally distributed. Give your best estimate of the probability that a sample mean RDI of 100 people is between 14 and 16 events per hour?

## Solution
The central limit theorem states that for a large enough sample size, the sample mean will approach a normal distribution.

```r
mean <- 15
sigma <- 10
n <- 100
SE <- sigma/sqrt(n)

lb <- 14
ub <- 16

round((pnorm(ub, mean=mean, sd=SE) - pnorm(lb, mean=mean, sd=SE))*100)
```

```
## [1] 68
```

## Question 7
Consider a standard uniform density. The mean for this density is .5 and the variance is 1 / 12. You sample 1,000 observations from this distribution and take the sample mean, what value would you expect it to be near?

## Solution
For a large number of samples, the sample mean should approximate the population mean, 0.5.

```r
quantile <- 0.5
mean <- 0.5
sigma <- 1/12
n <- 1000
SE <- mean/sqrt(n)

mean(runif(n, min=0, max=1))
```

```
## [1] 0.5043406
```

## Question 8
The number of people showing up at a bus stop is assumed to be Poisson with a mean of 5 people per hour. You watch the bus stop for 3 hours. About what's the probability of viewing 10 or fewer people?

## Solution

```r
t <- 3
rate <- 5
quantile <- 10

round(ppois(quantile, lambda=rate*t) * 100)
```

```
## [1] 12
```
