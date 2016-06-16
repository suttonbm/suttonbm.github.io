#!/usr/bin/env Rscript
                   
input <- commandArgs(trailingOnly = TRUE)
KnitPost <- function(input,
                     base.fig.path = "images/",
                     base.url = "{{ site.url }}/",
                     post.path = "")
{
    require(knitr)
    
    # Set base URL for links
    opts_knit$set(base.url = base.url)
    
    # Set to knit as Jekyll
    opts_knit$set(out.format = 'jekyll')
    
    # Set figure path to store images
    fig.path <- paste0(base.fig.path,
                       format(Sys.time(), "%Y/%m/"),
                       sub(".Rmd$", "", basename(input)), "/")
    opts_chunk$set(fig.path = fig.path)
    
    # Set figure caption
    opts_chunk$set(fig.cap = "center")
    
    print(paste0("_posts/", post.path, sub(".Rmd$", "", basename(input)), ".md"))
    
    knit(input, output = paste0("_posts/", sub(".Rmd$", "", basename(input)), ".md"), envir = parent.frame())
}