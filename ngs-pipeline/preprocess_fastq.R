# preprocess GSC FASTQ file to remote unwanted character(s)
#
# per Nanostring support 2024-05-09, the FASTQ with "/1" character would cause Nanostring DSP NGS pipeline
# to fail.
#
# solution provided by GSC.  Per email from Eric Chuah (GSC) 2024-05-16, the following commnad can remove
# the unwanted character:
# > zcat input.fastq.gz | sed 's/\/[12] / /1' | gzip > output.fastq.gz
#

# USER INPUT ------------------------------------------------------------------#
input_dir <- "/mnt/vm_shared/mapcore/SOW GSC-2547/fastq/22HJWNLT3_4/" # fastq files that needs extra character removed
output_dir <- "/mnt/vm_shared/mapcore/SOW GSC-2547/fastq_mod/22HJWNLT3_4/" # folder for processed fastq files with extra character removed
# END OF USER INPUT -----------------------------------------------------------#

# NO NEED TO MODIFY ANYTHING BELOW !!! #########################################################################

assertthat::assert_that(input_dir != output_dir,msg="input and output folders must be different!")
cat("preprocessing fastq files ... please wait ...")

sink(file.path(output_dir,"preprocess.log"))
cat("preprocess fastq files ...\n\n")
for (fname in dir(input_dir,pattern="*.fastq.gz")) {
    shell_cmd <- paste0(
        "zcat \"",file.path(input_dir,fname),"\" | sed 's/\\/[12] / /1' | gzip > \"",file.path(output_dir,fname),"\""
    )
    cat(shell_cmd,"\n")
    system(shell_cmd)
}
cat("\n")
cat("done. bye.",Sys.Date(),"\n")
sink()
cat("\n")
cat("done. bye.",Sys.Date(),"\n")
