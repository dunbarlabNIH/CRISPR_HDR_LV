## Script to merge barcode count files from BAR-seq
# 3/24/2021
# INPUT: Individual barcode count files from BAR-seq
# Output: A merged barcode count file and metadata file to use with barcodetrackR.

# BASH: REMOVE merge folder if it already exists!
cat("Running barcode merge, please make sure you are running from the correct directory\n")
cat("Parsing Args...\n")
args <- commandArgs(trailingOnly=TRUE)
i <- 0
for (arg in args) {
  i <- i + 1
  if (i==1) {
    path <- arg
  }
}
working_dir <- setwd(path)

working_dir <- getwd()
filename <- "merged"
output_dir <- file.path(working_dir, "output")

cat("Checking if output folder exists...\n")
stopifnot(dir.exists(output_dir))
cat("Output folder exists! Moving onto find tsv files...\n")
results_dir <- file.path(working_dir, "merge_results")
dir.create(results_dir)

tsv_files <- c()
labels <- c()
directories <- list.dirs(output_dir) # list sample directories in output folder
for (idx in 2:length(directories)) { # loop through all sample directories (1 is the parent folder)
  dir <- directories[idx] # get the specific sub directory full path
  f <- list.files(path=dir,pattern=".barcode.mc1*.tsv") # find the tsv count file####KS change to match output!!!!
  fpath <- file.path(dir,f) # create a path for directory and tsv file
cat(fpath)
cat(idx)  
cat("\n")
tsv_files[idx-1]=fpath # add tsv path to list
  split <- strsplit(dir, "/") 
  lab <- tail(split[[1]], n=1) # get the sub folder name to use as short label
  labels[idx-1] <- lab # add sub folder name to label list
}

print("Found relevent tsv files + labels, moving onto merge...")
merge_barcodes <- function(tsv_files,labels,filename) {  
  bc_counts_list <- list() # list containing each individual barcode count file
  for (i in 1:length(tsv_files)) {
    cat("Sample:", labels[i], "\n")
    bc_counts_list[[i]] <- read.delim(file = tsv_files[i], header = T)[,1:2]
    colnames(bc_counts_list[[i]]) <- c("bc","count")
    names(bc_counts_list)[i] <- labels[i]
    cat("Total barcode read count:",sum(bc_counts_list[[i]]$count), "\n")
    cat("Number of detected barcodes:",nrow(bc_counts_list[[i]]), "\n \n")
  }
  counts_df <- Reduce( # merge barcode counts
    function(x, y, ...) merge(x, y, by = "bc", all = TRUE, ...),
    bc_counts_list
  )
  counts_df[is.na(counts_df)] <- 0 # replace NAs with 0s
  # set rownames as barcode sequences and colnames as sample names
  rownames(counts_df) <- counts_df$bc
  counts_df$bc <- NULL
  colnames(counts_df) <- labels
  # create a metadata dataframe and print to file
  metadata_df <- data.frame(
    SAMPLENAME = labels,
    full_filename = tsv_files
  )
  write.table(counts_df, file = file.path(results_dir, paste(filename, "counts.txt", sep = "_")),
              sep = "\t", row.names = TRUE, col.names = NA, quote = FALSE)
  write.table(metadata_df, file = file.path(results_dir, paste(filename, "metadata.txt", sep = "_")),
              sep = "\t", row.names = F, quote = FALSE)
  output <- list(counts_df, metadata_df)
  return(output)
}
merge_barcodes(tsv_files,labels,filename)
