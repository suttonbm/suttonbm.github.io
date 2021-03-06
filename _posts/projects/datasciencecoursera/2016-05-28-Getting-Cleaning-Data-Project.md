---
title: "Getting and Cleaning Data"
date: 2016-05-28
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
  Getting/Cleaning Data Course Project
---



# JHU Data Science:
### Getting/Cleaning Data, Course Project

Source code and additional information regarding this post can be found on my [GitHub](https://github.com/suttonbm/datasciencecoursera/tree/master/Getting_Cleaning_Data/Project)

Introduction
------------
For the final project of the getting and cleaning data module of the JHU Coursera Specialization, students were asked to create an R script which would import data, clean it, apply some basic summary statistical functions, and output a "tidy" data set ready for further use.

In addition, we also created a readme with basic information about the script, as well as a codebook describing the variables in the final, tidy data set.

Description
-----------
__run_analysis.R__ is an R script that will download the Human Activity Recognition data set and perform the following operations:

* Import raw data into R and merge test/train data sets
* Assign movement/activity information as a factor with descriptive labels
* Exract only "features" pertaining to mean or standard deviation of measurements (see below for definition of feature)
* Assign descriptive column names for extracted features
* Summarize average data for each feature by test subject and activity in a separate, tidy data set

The source of the original data will be downloaded from:

[https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip)

Library Requirements
--------------------
In order to run __run_analysis.R__, you will require the plyr package.  To install, type `install_packages("plyr")` at the R command line.

Usage
-----
To use, simply run __run_analysis.R__ as a script.  To do this, type `source("run_analysis.R")` at the R command line.  After running the script, a variable called `tidydata` will be available in your local environment.  This variable contains the processed data.  For more information on the columns and meanings of the data, please refer to the codebook (CodeBook.md).

Note that the data is also saved to a text file with `write_table()`.  The file name will be `UCI_Tidy.txt`.  To re-import the tidy data set, enter `data <- read_table("UCI_Tidy.txt", header=TRUE)` at the R command line.  Be sure your current working directory contains `UCI_Tidy.txt` or navigate to the correct directory first using `setwd()`.

The Script
==========

```r
data.location <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
zipfile.name <- "dataset.zip"

## Download data and unzip into current working directory
download.file(data.location, zipfile.name)
unzip(zipfile.name)

## Set appropriate working directory
old.wd <- getwd()
setwd("UCI HAR Dataset")

## Read code rings for activities and features to allow automatic column naming
feature.codering <- read.table('features.txt', col.names=c("id", "label"))
activity.codering <- read.table('activity_labels.txt',
                                col.names=c("id", "activity"))

## Read in subject list.  Note data is merged inline.
subjects <- rbind(read.table('test/subject_test.txt',
                             col.names=c("subject.id")),
                  read.table('train/subject_train.txt',
                             col.names=c("subject.id")))
subjects$subject.id <- factor(subjects$subject.id)

## Read in activity data and create a factor to name the activities.
## Note data is merged inline.
activities <- rbind(read.table('test/y_test.txt',
                               col.names=c("activity")),
                    read.table('train/y_train.txt',
                               col.names=c("activity")))
activities$activity <- factor(activities$activity,
                     levels=activity.codering$id,
                     labels=activity.codering$activity)

## Read in raw features data.  Note that columns are not named at
## this time; names will be created and applied once selecting
## only the relevant columns from the dataset.
rawdata <- rbind(read.table('test/X_test.txt'),
                 read.table('train/X_train.txt'))

## Determine feature columns to select
## Only columns with mean or std deviation data are selected
meanrows <- grep("^[a-zA-Z]+-mean\\(\\)", feature.codering$label)
stdrows <- grep("^[a-zA-Z]+-std\\(\\)", feature.codering$label)
feature.cols <- c(meanrows, stdrows)
feature.names <- feature.codering$label[feature.cols]
feature.names <- as.character(feature.names)

## Make column names pretty
for(j in 1:length(feature.names)) {
    currentName <- feature.names[j]
    currentName <- gsub("-", ".", currentName)
    currentName <- gsub("[\\(\\)]", "", currentName)
    feature.names[j] <- currentName
}

## Filter to relevant columns and apply pretty names to selected
## columns
rawdata.relevant <- rawdata[,feature.cols]
names(rawdata.relevant) <- feature.names

## Join selected data with subjects and activities to form one table
alldata <- cbind(subjects, activities, rawdata.relevant)

## Create tidy data set with average measurements for each subject
## activity combination
library(plyr)
tidydata <- ddply(alldata, .(subject.id, activity), colwise(mean))

## Restore original working directory and export tidy data set
setwd(old.wd)
write.table(tidydata, file="UCI_Tidy.txt")
```
