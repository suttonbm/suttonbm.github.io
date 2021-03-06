---
title: "Statistical Inference"
date: 2016-04-30T7:47
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
  Quiz 4
---



# Quiz 4

### Question 1
A pharmaceutical company is interested in testing a potential blood pressure lowering medication. Their first examination considers only subjects that received the medication at baseline then two weeks later. The data are as follows (SBP in mmHg):

Subject | Baseline  | Week2
------- | --------  | -----
1       | 140       | 132
2       | 138       | 135
3       | 150       | 151
4       | 148       | 146
5       | 135       | 130

Consider testing the hypothesis that there was a mean reduction in blood pressure? Give the P-value for the associated two sided T test.

### Solution

```r
sub <- c(1, 2, 3, 4, 5)
baseline <- c(140, 138, 150, 148, 135)
week_2 <- c(132, 135, 151, 146, 130)

exams <- data.frame(sub, baseline, week_2)
exams
```

```
##   sub baseline week_2
## 1   1      140    132
## 2   2      138    135
## 3   3      150    151
## 4   4      148    146
## 5   5      135    130
```

```r
test <- t.test(x=exams$baseline, y=exams$week_2, alt="two.sided", paired=TRUE)
p_Val <- test$p.value
round(p_Val, 3)
```

```
## [1] 0.087
```

### Question 2
A sample of 9 men yielded a sample average brain volume of 1,100cc and a standard deviation of 30cc. What is the complete set of values of ??0 that a test of $$(H_0:\mu=\mu_0)$$ would fail to reject the null hypothesis in a two sided 5% Students t-test?

### Solution

```r
alpha <- 0.05
n <- 9
avg <- 1100
s <- 30

T_bound <- c(1,-1)*qt(alpha/2, df=n-1)
confidenceBound <- avg + T_bound*s/sqrt(n)
confidenceBound
```

```
## [1] 1076.94 1123.06
```

### Question 3
Researchers conducted a blind taste test of Coke versus Pepsi. Each of four people was asked which of two blinded drinks given in random order that they preferred. The data was such that 3 of the 4 people chose Coke. Assuming that this sample is representative, report a P-value for a test of the hypothesis that Coke is preferred to Pepsi using a one sided exact test.

### Solution

```r
n <- 4
x <- 3
test <- binom.test(x=x, n=n, alt="greater")
round(test$p.value, 2)
```

```
## [1] 0.31
```

### Question 4
Infection rates at a hospital above 1 infection per 100 person days at risk are believed to be too high and are used as a benchmark. A hospital that had previously been above the benchmark recently had 10 infections over the last 1,787 person days at risk. About what is the one sided P-value for the relevant test of whether the hospital is below the standard?

### Solution

```r
rate_0 <- 1/100
errs <- 10
days <- 1787
test <- poisson.test(errs, T = days, r = rate_0, alt="less")
round(test$p.value, 2)
```

```
## [1] 0.03
```

### Question 5
Suppose that 18 obese subjects were randomized, 9 each, to a new diet pill and a placebo. Subjects' body mass indices (BMIs) were measured at a baseline and again after having received the treatment or placebo for four weeks. The average difference from follow-up to the baseline (followup - baseline) was -3 kg/m2 for the treated group and 1 kg/m2 for the placebo group. The corresponding standard deviations of the differences was 1.5 kg/m2 for the treatment group and 1.8 kg/m2 for the placebo group. Does the change in BMI appear to differ between the treated and placebo groups? Assuming normality of the underlying data and a common population variance, give a pvalue for a two sided t test.

### Solution

```r
n1 <- 9
n2 <- 9
var1 <- 1.5^2
var2 <- 1.8^2
mean1 <- -3
mean2 <- 1

Sp <- sqrt(((n1-1)*var1 + (n2-2)*var2)/(n1+n2-2))
p_Val <- pt((mean1-mean2)/(Sp*sqrt(2/n1)), df=n1+n2-2)
p_Val
```

```
## [1] 3.441974e-05
```

### Question 6
Brain volumes for 9 men yielded a 90% confidence interval of 1,077 cc to 1,123 cc. Would you reject in a two sided 5% hypothesis test of $$(H_0:\mu=1,078)$$?

### Solution
No, 1,078 is included in the 90% confidence bounds, so the null hypothesis is not rejected.

### Question 7
Researchers would like to conduct a study of 100 healthy adults to detect a four year mean brain volume loss of .01 mm3. Assume that the standard deviation of four year volume loss in this population is .04 mm3. About what would be the power of the study for a 5% one sided test versus a null hypothesis of no volume loss?

### Solution

```r
n <- 100
mean <- 0.01
sigma <- 0.04
alpha <- 0.05

round(power.t.test(n=n, delta=mean, sd=sigma, sig.level=alpha, type="one.sample", alt="one.sided")$power, 2)
```

```
## [1] 0.8
```

### Question 8
Researchers would like to conduct a study of n healthy adults to detect a four year mean brain volume loss of .01 mm3. Assume that the standard deviation of four year volume loss in this population is .04 mm3. About what would be the value of n needded for 90% power of type one error rate of 5% one sided test versus a null hypothesis of no volume loss?

### Solution

```r
mean <- 0.01
sigma <- 0.04
alpha <- 0.05
power <- 0.9

n <- power.t.test(power=power, delta=mean, sd=sigma, sig.level=alpha, type="one.sample", alt="one.sided")$n
ceiling(n/10)*10
```

```
## [1] 140
```

### Question 9
As you increase the type one error rate, $$\alpha$$, what happens to power?

### Solution
Power increases if you increase the false positive rate $$\alpha$$.
