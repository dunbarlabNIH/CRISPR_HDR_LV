## Script to merge barcode count files from BAR-seq
# 3/24/2021
# INPUT: Individual barcode count files from BAR-seq
# Output: A merged barcode count file and metadata file to use with barcodetrackR.
# TEST COUNT DATA: /Users/gricemz/Desktop/gitRepo/BarcodingPrivate/MONKEYS/Diana/M11021072/05_4_2022/merge_results/merged_counts.txt

# BASH: REMOVE merge folder if it already exists!
cat("Running barcode merge, please make sure you are running from the correct directory\n")
cat("Parsing Args...\n")
args <- commandArgs(trailingOnly=TRUE)
i <- 0
for (arg in args) {
  i <- i + 1
  if (i==1) {
    old_count_path <- arg
  }
if (i==2) {
path <- arg
}
}
working_dir <- setwd(path)
working_dir <- getwd()
filename <- "merged"
output_dir <- file.path(working_dir, "output")
old_counts <- read.table(file = old_count_path, header = T, sep = "\t", row.names = 1)

cat(paste("Checking if output folder ", output_dir, "exists...\n", sep=""))
stopifnot(dir.exists(output_dir))
cat("Output folder exists! Moving onto find tsv files...\n")
results_dir <- file.path(working_dir, "merge_results")
dir.create(results_dir)

tsv_files <- c()
labels <- c()
directories <- list.dirs(output_dir) # list sample directories in output folder
for (idx in 2:length(directories)) { # loop through all sample directories (1 is the parent folder)
  dir <- directories[idx] # get the specific sub directory full path
  f <- list.files(path=dir,pattern=".barcode.mc1.tsv") # find the tsv count file
  fpath <- file.path(dir,f) # create a path for directory and tsv file
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
  current_sample_idx <- length(tsv_files)+1
  old_and_new_samples <- length(tsv_files)+length(colnames(old_counts))
  for (j in current_sample_idx:old_and_new_samples) {
    idx <- j-length(tsv_files)
    cat("Old Sample:", colnames(old_counts)[idx], "\n")
    bc_counts_list[[j]] <- cbind(rownames(old_counts),old_counts[,idx])
    colnames(bc_counts_list[[j]]) <- c("bc","count")
    bc_counts_list[[j]] <- as.data.frame(bc_counts_list[[j]])
    bc_counts_list[[j]]$count <- as.integer(bc_counts_list[[j]]$count)
    names(bc_counts_list)[j] <- colnames(old_counts)[idx]
    cat("Total OLD barcode read count:",sum(bc_counts_list[[j]]$count), "\n")
    cat("Number OLD of detected barcodes:",nrow(bc_counts_list[[j]]), "\n \n")
  }
  
  counts_df <- Reduce( # merge barcode counts
    function(x, y, ...) merge(x, y, by = "bc", all = TRUE, ...),
    bc_counts_list
  )
  counts_df[is.na(counts_df)] <- 0 # replace NAs with 0s
  # set rownames as barcode sequences and colnames as sample names
  rownames(counts_df) <- counts_df$bc
  counts_df$bc <- NULL
  all_labels <- c(labels, colnames(old_counts))
  colnames(counts_df) <- all_labels
  # create a metadata dataframe and print to file
  metadata_df <- data.frame(
    SAMPLENAME = all_labels
    #full_filename = tsv_files
  )
  write.table(counts_df, file = file.path(results_dir, paste(filename, "counts.txt", sep = "_")),
              sep = "\t", row.names = TRUE, col.names = NA, quote = FALSE)
  write.table(metadata_df, file = file.path(results_dir, paste(filename, "metadata_labels.txt", sep = "_")),
              sep = "\t", row.names = F, quote = FALSE)
  output <- list(counts_df, metadata_df)
  return(output)
}
merge_barcodes(tsv_files,labels,filename)
