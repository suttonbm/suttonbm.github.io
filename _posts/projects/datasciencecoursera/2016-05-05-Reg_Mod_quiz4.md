---
title: "Regression Models"
date: 2016-05-05T11:48
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
Consider the space shuttle data `shuttle` in the `MASS` library. Consider modeling the use of the autolander as the outcome (variable name `use`Fit a logistic regression model with autolander (`auto`) use (`auto=1`) versus not (`auto=0`) as predicted by wind sign (`wind`). Give the estimated odds ratio for autolander use comparing head winds, labeled as (`wind="head"`) in the variable headwind (numerator) to tail winds (denominator).

### Solution

```r
library(MASS)
shuttle$auto <- as.integer(shuttle$use == "auto")
model <- glm(auto ~ wind - 1, "binomial", data=shuttle)
coef <- exp(coef(model))
(oddsratio <- coef[1]/coef[2])
```

```
##  windhead 
## 0.9686888
```

### Question 2
Consider the previous problem. Give the estimated odds ratio for autolander use comparing head winds (numerator) to tail winds (denominator) adjusting for wind strength from the variable `magn`.

### Solution

```r
model2 <- glm(auto ~ wind + magn - 1, "binomial", data=shuttle)
coef2 <- exp(coef(model2))
(oddsratio2 <- coef2[1]/coef2[2])
```

```
##  windhead 
## 0.9684981
```

### Question 3
If you fit a logistic regression model to a binary variable, for example use of the autolander, then fit a logistic regression model for one minus the outcome (not using the autolander) what happens to the coefficients?

### Solution

```r
model3 <- glm(I(1 - auto) ~ wind - 1, "binomial", data=shuttle)
rbind(coef(model), coef(model3))
```

```
##        windhead   windtail
## [1,]  0.2513144  0.2831263
## [2,] -0.2513144 -0.2831263
```
The coefficients reverse their signs.

### Question 4
Consider the insect spray data `InsectSprays`. Fit a Poisson model using spray as a factor level. Report the estimated relative rate comapring spray A (numerator) to spray B (denominator).

### Solution

```r
data(InsectSprays)
model4 <- glm(count ~ spray - 1, "poisson", data=InsectSprays)
coef4 <- exp(coef(model4))
coef4[1]/coef4[2]
```

```
##    sprayA 
## 0.9456522
```

### Question 5
Consider a Poisson glm with an offset, t. So, for example, a model of the form:
`model5 <- glm(count ~ x + offset(t), family="poisson")`
where `x` is a factor variable comparing a treatment to a control, and `t` is the natrual log of a monitoring time.  What is the impact of the coefficient for `x` if we fit the model:
`model6 <- glm(count ~ x + offset(t2), family="poisson")`
where `t2 <- log(10) + t1`?
In other words, what happens to the coefficients if twe change the units of the offset variable?

### Solution
The coefficient estimate is unchanged.

### Question 6
Consider:

```r
x <- -5:5
y <- c(5.12, 3.93, 2.67, 1.87, 0.52, 0.08, 0.93, 2.05, 2.54, 3.87, 4.97)
```
Using a knot point at `x=0`, fit a linear model that looks like a hockey stick with two lines meeting at `x=0`.  Include an intercept term, `x`, and the knot point term.  What is the estimated slope of the line for `x>0`?

### Solution
The simplest way to get a piecewise linear model is using the "segmented" package:

```r
library(segmented)
model6 <- lm(y ~ x)
model6.segmented <- segmented(model6, seg.Z = ~x, psi=0)
summary(model6.segmented)
```

```
## 
## 	***Regression Model with Segmented Relationship(s)***
## 
## Call: 
## segmented.lm(obj = model6, seg.Z = ~x, psi = 0)
## 
## Estimated Break-Point(s):
##    Est. St.Err 
## -0.264  0.107 
## 
## Meaningful coefficients of the linear terms:
##             Estimate Std. Error t value Pr(>|t|)    
## (Intercept) -0.55600    0.18899  -2.942   0.0217 *  
## x           -1.12600    0.05698 -19.761 2.12e-07 ***
## U1.x         2.09057    0.07143  29.267       NA    
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## 
## Residual standard error: 0.1802 on 7 degrees of freedom
## Multiple R-Squared: 0.9923,  Adjusted R-squared: 0.9891 
## 
## Convergence attained in 3 iterations with relative change -3.404285e-15
```

```r
slope(model6.segmented)
```

```
## $x
##           Est. St.Err. t value CI(95%).l CI(95%).u
## slope1 -1.1260 0.05698  -19.76   -1.2610   -0.9913
## slope2  0.9646 0.04307   22.39    0.8627    1.0660
```

```r
plot(x, y, pch=16)
plot(model6.segmented, add=T)
```

![center](http://i.imgur.com/5ZF0Vgd.png)
