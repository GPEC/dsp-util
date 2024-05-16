# change GSC FASTQ file name to Nanostirng compatible file name
#
# per Nanostring support 2022-08-26 the FASTQ file name convention is:
# DSP-PlateNumber, seq code plate letter, GeoMx Plate Well Number, sample sheet number, lane, R1/R2, always end in '001'
# DSP-1001250001985-D-A02_S2_L001_R2_001.fastq.gz
#
# note:
# - lane number: L001, L002, etc do not have to match anything in particular for the standalone pipeline, they just indicate that the fastqs are separate lanes of the same sample and should be combined by the pipeline.
# - Sample sheet number is based on the illumina sample sheet submitted with the sequencing run, but it is not directly used by the pipeline, it simply needs to be there to allow the rest of the file name to be parsed correctly.
# - Usually when using standard bcl2fastq settings with splitting by lane on, the name sorts itself out. However, some cores have started using newer demultiplexing settings or have custom naming schemes which makes the name not match.

# USER INPUT ------------------------------------------------------------------#
# sequence code indices file
code_indices_fname <- "/mnt/vm_shared/mapcore/SOW GSC-2547/REVERSE_SOW0745 PCBC DSP_20240308T2231_SeqCodeIndices.csv"
fastq_dir <- "/mnt/vm_shared/mapcore/SOW GSC-2547/fastq/22HJWNLT3_5"
sheet_name <- "S1" # not directly used by pipeline ... any non-empty value would work.
lane <- "L002" # TODO ... NEXT TIME SHOULD TRY READ FROM FILE FROM GSC!!! e.g. from GSC-2216_IX10953_HNKLKDSX3_2_gsc_library.summary
ending <- "001" # do not change ... always end in '001'
indices_file_specimen_id_col <- "index" # the column name of code_indices_fname that should uniquely identifies specimen
# END OF USER INPUT -----------------------------------------------------------#

### the following should not need to be be changed #############################
log_fname <- file.path(fastq_dir,"rename.log")
sink(log_fname)
cat("change file name GSC format to Nanostring format ...\n")
cat("FASTQ dir:",fastq_dir,"\n")

# can only work with one fastq folder at a time!
assertthat::assert_that(length(fastq_dir)==1)

# lookup fastq files
all_fastq_files <- dir(fastq_dir,pattern="*.fastq.gz",full.names = FALSE)

c_indices_d <- read.csv(code_indices_fname,header=TRUE,stringsAsFactors=FALSE)
# make sure sample id column do uniquely identify specimen
assertthat::assert_that(length(unique(c_indices_d[,indices_file_specimen_id_col]))==nrow(c_indices_d), msg="unable to find unique match in indices file for some file(s)")

lookup_fname <- function(target_seq) {
  # only match first sequence e.g.
  # PX2676_CTCCGTAC-CGTTAAGC_1_150bp_4_lanes.merge.fastq.gz
  # match with "CTCCGTAC"
  all_fastq_files[grep(paste0("_",target_seq,"-"),all_fastq_files)]
}

# given GSC file name e.g. HNKLKDSX3_2_1_GATATCTG-TGCAGAAT_150bp.concat.fastq.gz
# assume this is the 3rd element if delimited by "_"
lookup_r <- function(gsc_fname) {
  temp <- strsplit(gsc_fname,"_")[[1]]
  assertthat::assert_that(length(temp)>3,msg=paste("invalid file name: ",gsc_fname))
  return(paste0("R",temp[3]))
}

# iterate through all specimen name in c_indices_d
fname_map_d <- data.frame(
  org_fname="",
  new_fname=""
)
for (i in 1:nrow(c_indices_d)) {
  sample_id <- c_indices_d$Sample_ID[i]
  target_seq <- c_indices_d[i,indices_file_specimen_id_col]
  
  # lookup file names
  for (fname in lookup_fname(target_seq)) {
    new_fname <- paste0(paste(sample_id,sheet_name,lane,lookup_r(fname),ending,sep="_"),".fastq.gz")
    fname_map_d <- rbind(
      fname_map_d,
      c(fname,new_fname)
    )
  }
}
fname_map_d <- fname_map_d[-1,]

# make sure new file names are unique!!!
# otherwise, we will be overwriting files!
assertthat::assert_that(length(unique(fname_map_d$new_fname))==nrow(fname_map_d))

# rename files!
cat("renaming files ...\n")
for (i in 1:nrow(fname_map_d)) {
  org_basename <- fname_map_d$org_fname[i]
  new_basename <- fname_map_d$new_fname[i]
  org_fname <- file.path(fastq_dir,org_basename)
  new_fname <- file.path(fastq_dir,new_basename)
  
  if (file.exists(org_fname)) {
    if (file.exists(new_fname)) {
      cat("skiping",new_fname,"since it exists already.\n")
    } else {
      cat(org_basename,"->",new_basename,"\n")
      file.rename(org_fname,new_fname)
    }
  } else {
    warning(paste(org_fname,"not found!"))
  }
}
cat("\ndone.\n")

cat(date())
cat("\n")
sink()
cat(paste0("rename completed; output sent to",log_fname,".\n"))