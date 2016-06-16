---
title: "Regression Models"
date: 2016-05-05T11:13
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
  Quiz 3
---



# Quiz 3

### Question 1
Consider the `mtcars` data set. Fit a model with mpg as the outcome that includes number of cylinders as a factor variable and weight as confounder. Give the adjusted estimate for the expected change in mpg comparing 8 cylinders to 4.

### Solution

```r
data("mtcars")
mtcars$cyl <- factor(mtcars$cyl)
model <- lm(mpg ~ cyl + wt - 1, data=mtcars)
(coef <- summary(model)$coef)
```

```
##       Estimate Std. Error   t value     Pr(>|t|)
## cyl4 33.990794  1.8877934 18.005569 6.257246e-17
## cyl6 29.735212  2.5409594 11.702356 2.687977e-12
## cyl8 27.919934  3.0914645  9.031297 8.680975e-10
## wt   -3.205613  0.7538957 -4.252065 2.130435e-04
```

```r
(diff <- coef["cyl8","Estimate"] - coef["cyl4","Estimate"])
```

```
## [1] -6.07086
```

### Question 2
Consider the `mtcars` data set. Fit a model with mpg as the outcome that includes number of cylinders as a factor variable and weight as a possible confounding variable. Compare the effect of 8 versus 4 cylinders on mpg for the adjusted and unadjusted by weight models. Here, adjusted means including the weight variable as a term in the regression model and unadjusted means the model without weight included. What can be said about the effect comparing 8 and 4 cylinders after looking at models with and without weight included?

### Solution

```r
model2 <- lm(mpg ~ cyl - 1, data=mtcars)
rbind(summary(model)$coef[1:3, 1], summary(model2)$coef[,1])
```

```
##          cyl4     cyl6     cyl8
## [1,] 33.99079 29.73521 27.91993
## [2,] 26.66364 19.74286 15.10000
```
Cylinder appears to have less of an impact on MPG if weight is included as a confounder.

### Question 3
Consider the `mtcars` data set. Fit a model with mpg as the outcome that considers number of cylinders as a factor variable and weight as confounder. Now fit a second model with mpg as the outcome model that considers the interaction between number of cylinders (as a factor variable) and weight. Give the P-value for the likelihood ratio test comparing the two models and suggest a model using 0.05 as a type I error rate significance benchmark.

### Solution

```r
model3 <- lm(mpg ~ cyl * wt - 1, data=mtcars)
anova(model, model3)
```

```
## Analysis of Variance Table
## 
## Model 1: mpg ~ cyl + wt - 1
## Model 2: mpg ~ cyl * wt - 1
##   Res.Df    RSS Df Sum of Sq      F Pr(>F)
## 1     28 183.06                           
## 2     26 155.89  2     27.17 2.2658 0.1239
```
P-value is greater than 0.05. For our criterion of $\alpha=0.05$, the interaction term may not be necessary.

### Question 4
Consider the `mtcars` data set. Fit a model with mpg as the outcome that includes number of cylinders as a factor variable and weight inlcuded in the model as:

```r
model4 <- lm(mpg ~ I(wt * 0.5) + factor(cyl), data = mtcars)
```
How is the wt coefficient interpreted?

### Solution
The expected change in MPG per one ton increase in weight for a specific number of cylinders (4, 6, 8).  Since the units of wt are 1/1000lb, scaling by 0.5 changes units to 1/2000lb.

### Question 5
Consider:

```r
x <- c(0.586, 0.166, -0.042, -0.614, 11.72)
y <- c(0.549, -0.026, -0.127, -0.751, 1.344)
```
Give the hat diagonal for the most influential point.

### Solution

```r
model5 <- lm(y ~ x)
hats <- hatvalues(model5)
max(hats)
```

```
## [1] 0.9945734
```

### Question 6
Using the same data from question 5, give the slope dfbeta for the point with the highest hat value.

### Solution

```r
maxHatPos <- as.character(which.max(hats))
dfbetas(model5)[maxHatPos, "x"]
```

```
## [1] -133.8226
```

### Question 7
Consider a regression relationship between Y and X with and without adjustment for a third variable Z. Which of the following is true about comparing the regression coefficient between Y and X with and without adjustment for Z.

### Solution
It is possible for the coefficient to reverse sign afer adjustment.
