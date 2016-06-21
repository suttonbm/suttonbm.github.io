#!/usr/bin/env Rscript
                   
my_imgur_upload <- function(file) {
  require(knitr)
  return(imgur_upload(file, key="07297ec2f36c88f"))
}

KnitPost <- function(input,
                     base.url = "{{ site.url }}",
                     post.path = "_posts/")
{
    require(knitr)
    
    # Set base URL for links
    opts_knit$set(base.url = base.url)
    
    # Set to knit as Jekyll
    opts_knit$set(out.format = 'jekyll')
    
    # Set images to load from imgur
    opts_knit$set(upload.fun = my_imgur_upload)
    
    # Set figure caption
    opts_chunk$set(fig.cap = "center")
    
    print(paste0(post.path,
                 sub(".Rmd$", "", basename(input)),
                 ".md"))
    
    knit(input,
         output = paste0(post.path,
                         sub(".Rmd$", "",basename(input)),
                         ".md"),
         envir = parent.frame())
}