# CRISPR_HDR_LV
This repository is for the data and scripts used in the “Impact of CRISPR/HDR-editing versus lentiviral transduction on long-term engraftment and clonal dynamics of HSPCs in rhesus macaques” paper by Lee et al.![image](https://github.com/dunbarlabNIH/CRISPR_HDR_LV/assets/147164407/126ea7be-069a-4802-831a-66c76e8b2d8d)

•	Figures 3C-E, 6A-B, 6D-E, 7A-F (Extracted Barcodes and Counts):
o	Within “Scripts”, “BARseq_scripts_for_HDR_barcode_extraction” and “BARseq_scripts_for_LV_barcode_extraction” contain all code scripts and sample run.txt files for HDR and lentiviral genetic barcode extraction, respectively. Outputs from these scripts are merged via “merge_barseq_counts_files.R” to generate the metadata and counts files needed for input into barcodetrackR (https://github.com/dunbarlabNIH/barcodetrackR.git)
o	“Barcode_data” provides all BARseq outputs organized by animal, and the merged BARseq metadata and counts files needed for input into barcodetrackR (https://github.com/dunbarlabNIH/CRISPR_HDR_LV/assets/147164407/76583062-c873-40d9-83ba-551de11135f2)

•	Figures 3A-D, 5A-B (Editing Efficiency):
o	Within “Scripts”, “Miseq_trim.swarm” contains the script used to trim the original fastq files, and “crispresso_CD33_editing_efficiency.swarm” contains a sample swarm file for running crispresso.
o	“CD33_EditingEfficiency_Data” provides sample raw and trimmed fastq files for each of the three animals
