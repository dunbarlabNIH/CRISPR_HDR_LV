## Script to merge barcode count files from BAR-seq
# 06/16/2023
# INPUT: Individual barcode count files from BAR-seq
# Output: A merged barcode count file and metadata file to use with barcodetrackR.

## EDIT THIS INFORMATION HERE ########################################################################################################
## The directory on your computer where this script is sitting.
base_directory <-  "/Volumes/LAB/Ashley_Gin/3_HDR/Barcoding/barseq_merge"

## Input file paths. Include the directory if the files are in folders e.g. "BL5651_41/BL5651_41_S41_L001_R1_001_trimmed.barcode.mc1"
barseq_files <- c(
  "Animal1_PBGr/BL-7989_2_S2_L002_R1_001.barcode.mc100.tsv",
  "Animal1_PBGr/BL-7989_5_S5_L002_R1_001.barcode.mc100.tsv",
  "Animal1_PBGr/BL-7989_6_S6_L002_R1_001.barcode.mc100.tsv",
  "Animal1_PBGr/BL-7989_11_S11_L002_R1_001.barcode.mc100.tsv"
)

## Sample names. Could be the same as the filenames but it might be more convenient to have shortened sample names.
samplenames <- c(
  "Animal1_PBGr_1m",
  "Animal1_PBGr_4m",
  "Animal1_PBGr_5m",
  "Animal1_PBGr_10m"
)

## Set results directory and filename for your output folder
results_directory <- file.path(base_directory)
results_filename <- "Animal1_CRISPR_PBGr_merged"
#######################################################################################################################################


## Below here is the script and you do not need to change anything
# Make a list containing each individual barcode count file
bc_counts_list <- list()
for (i in 1:length(barseq_files)){
  cat("Sample:", samplenames[i], "\n")
  bc_counts_list[[i]] <- read.delim(file = file.path(base_directory, barseq_files[i]), header = T)[,1:2]
  colnames(bc_counts_list[[i]]) <- c("bc","count")
  names(bc_counts_list)[i] <- samplenames[i]
  cat("Total barcode read count:",sum(bc_counts_list[[i]]$count), "\n")
  cat("Number of detected barcodes:",nrow(bc_counts_list[[i]]), "\n \n")
}

# Merge the barcode counts
counts_df <- Reduce(
  function(x, y, ...) merge(x, y, by = "bc", all = TRUE, ...),
  bc_counts_list
)

# Replace NAs with 0s
counts_df[is.na(counts_df)] <- 0

# Set rownames as barcode sequences and colnames as sample names
rownames(counts_df) <- counts_df$bc
counts_df$bc <- NULL
colnames(counts_df) <- samplenames

# Create a metadata dataframe
metadata_df <- data.frame(
  SAMPLENAME = samplenames,
  full_filename = barseq_files
)

# Print files
write.table(counts_df, file = file.path(results_directory, paste(results_filename, "counts.txt", sep = "_")),
            sep = "\t", row.names = TRUE, col.names = NA, quote = FALSE)

write.table(metadata_df, file = file.path(results_directory, paste(results_filename, "metadata.txt", sep = "_")),
            sep = "\t", row.names = F, quote = FALSE)

