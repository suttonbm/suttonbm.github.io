---
title: "Regression Models"
date: 2016-05-02
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

### Question 1
Consider:

```r
x <- c(0.61, 0.93, 0.83, 0.35, 0.54, 0.16, 0.91, 0.62, 0.62)
y <- c(0.67, 0.84, 0.6, 0.18, 0.85, 0.47, 1.1, 0.65, 0.36)
```
Give a P-value for the two sided hypothesis test of whether $$\beta_1$$ from a linear regression model is 0 or not.

### Solution
There are two solutions. The "easy" way is using a linear model:

```r
model <- lm(y ~ x)
coef(summary(model))
```

```
##              Estimate Std. Error   t value   Pr(>|t|)
## (Intercept) 0.1884572  0.2061290 0.9142681 0.39098029
## x           0.7224211  0.3106531 2.3254912 0.05296439
```
Or manual calculation:

```r
n <- length(y)
beta1 <- cor(y, x) * sd(y) / sd(x)
beta0 <- mean(y) - beta1 * mean(x)
err <- y - beta0 - beta1*x
sigma <- sqrt(sum(err^2)/(n-2))
ssx <- sum((x - mean(x))^2)
stdErrBeta1 <- sigma / sqrt(ssx)
tBeta1 <- beta1 / stdErrBeta1
(p_Beta1 <- 2 * pt(abs(tBeta1), df=n-2, lower.tail=FALSE))
```

```
## [1] 0.05296439
```

### Question 2
Consider the previous problem, give the estimate of the residual standard deviation.

### Solution
Using linear model:

```r
summary(model)$sigma
```

```
## [1] 0.2229981
```
Manually

```r
(sigma <- sqrt(sum(err^2) / (n-2)))
```

```
## [1] 0.2229981
```

### Question 3
In the `mtcars` data set, fit a linear regression model of weight (predictor) on mpg (outcome). Get a 95% confidence interval for the expected mpg at the average weight. What is the lower endpoint?

### Solution

```r
data(mtcars)
model <- lm(mpg ~ wt, data=mtcars)
predict(model, newdata = data.frame(wt = mean(mtcars$wt)), interval = ("confidence"))
```

```
##        fit      lwr      upr
## 1 20.09062 18.99098 21.19027
```

### Question 4
Refer to the previous question. Read the help file for `mtcars`. What is the weight coefficient interpreted as?

### Solution
Variable `wt` has units of lb/1000. Therefore, the coefficient is interpreted as the expected change in `mpg` per 1000lb increase in `wt`.

### Question 5
Consider again the `mtcars` data set and a linear regression model with mpg as predicted by weight (1,000 lbs). A new car is coming weighing 3000 pounds. Construct a 95% prediction interval for its mpg. What is the upper endpoint?

### Solution

```r
predict(model, newdata=data.frame(wt = 3), interval=("prediction"))
```

```
##        fit      lwr      upr
## 1 21.25171 14.92987 27.57355
```

### Question 6
Consider again the `mtcars` data set and a linear regression model with mpg as predicted by weight (in 1,000 lbs). A "short" ton is defined as 2,000 lbs. Construct a 95% confidence interval for the expected change in mpg per 1 short ton increase in weight. Give the lower endpoint.

### Solution
One way to calculate this value is to adjust the units of the predictor.

```r
model <- lm(mpg ~ I(wt/2), data=mtcars)
sumCoef <- coef(summary(model))
(sumCoef[2,1] + c(-1,1) * qt(0.975, df=model$df) * sumCoef[2,2])
```

```
## [1] -12.97262  -8.40527
```

### Question 7
If my $$X$$ from a linear regression is measured in centimeters and I convert it to meters what would happen to the slope coefficient?

### Solution
The slope would be multiplied by 100.

### Question 8
I have an outcome, $$Y$$, and a predictor, $$X$$ and fit a linear regression model with $$Y=\beta_0+\beta_1X+\epsilon$$ to obtain $$\hat{\beta_0}$$ and $$\hat{\beta_1}$$. What would be the consequence to the subsequent slope and intercept if I were to refit the model with a new regressor, $$X+c$$ for some constant, $$c$$?

### Solution
The new intercept would be $$\hat{\beta_0}-c\hat{\beta_1}$$:

```r
x <- c(1,2,3,4,5)
y <- c(4,5,6,7,8)
fit <- lm(y ~ x)
fit$coef
```

```
## (Intercept)           x 
##           3           1
```

```r
x2 <- x+10
fit_c <- lm(y ~ x2)
fit_c$coef
```

```
## (Intercept)          x2 
##          -7           1
```

```r
fit$coef[1] - 10*fit$coef[2]
```

```
## (Intercept) 
##          -7
```

### Question 9
Refer back to the `mtcars` data set with `mpg` as an outcome and weight (`wt`) as the predictor. About what is the ratio of the the sum of the squared errors when comparing a model with just an intercept (denominator) to the model with the intercept and slope (numerator)?

### Solution

```r
data(mtcars)
model <- lm(mpg ~ wt, data=mtcars)
sum(resid(model)^2) / sum((mtcars$mpg - mean(mtcars$mpg)) ^ 2)
```

```
## [1] 0.2471672
```

### Question 10
Do the residuals always have to sum to 0 in linear regression?

### Solution
If an intercept is included, then they will sum to 0.
