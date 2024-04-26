# check md5sum
# 
# this file does NOT generate MD5 sum.
library(assertthat)

# need to change the following to point to correct files related to your project
pre_fname <-"/mnt/vm_shared/mapcore/SOW GSC-2543/fastq/md5sum_results.txt" 
post_fname <- "/mnt/vm_shared/mapcore/SOW GSC-2543/fastq/md5sum_check.txt" 

########################################
### no need to change anything below ###
########################################

cat("checking MD5 sums of downloaded fastq files ...\n")
cat("MD5 sum given by GSC: ",pre_fname,"\n")
cat("MC5 sum generated after download: ",post_fname,"\n")
cat("...")

pre_d <- read.delim(pre_fname,header=FALSE,sep=" ")
post_d <- read.delim(post_fname,header=FALSE,sep=" ")


# format
pre_d$fname <- sub("./","",pre_d$V3,fixed=TRUE)
post_d$fname <- sapply(post_d$V3,function(x){
  temp <- strsplit(x,"/")[[1]]
  return(temp[length(temp)])
})
assertthat::assert_that(sum(post_d$fname %in% pre_d$fname)==nrow(post_d))

pre_d$md5sum <- pre_d$V1
post_d$md5sum <- post_d$V1

# make sure all md5sum in post file is same as pre file
assertthat::assert_that(
  sum(pre_d$md5sum[match(post_d$fname,pre_d$fname)]==post_d$md5sum)==nrow(post_d),
  msg="md5sum check FAILED!!!")

cat("done. MD5 sum consistent.\n")
