import os 
import glob
import pandas as pd
import sys

#print('Number of arguments: '+str(len(sys.argv))+' arguments.')
#print('Argument List: '+ str(sys.argv))

barcodes_distinct_filtered=[]
barcodes_distinct_merged=[]
barcodes_total_counts_merged=[]
total_reads=[]
total_extracted_reads=[]
samples=[]

parse_BARseq=["Barcodes after filter","Barcodes after merge","Sum of all barcode counts"]
parse_tagdust=["total input reads", "successfully extracted"]

cwd=sys.argv[1]
# /Users/gricemz/Desktop/gitRepo/BarcodingPrivate/MONKEYS/HAWH/5_25_22_CRISPR
output_path=cwd+"/output"
output_dirs=[x[0] for x in os.walk(output_path)]
output_dirs=output_dirs[1:] # first item in list is the parent directory so remove it!

for d in output_dirs: # loop through all sample output directories
	lab=os.path.basename(d) # get the short name for the sample
	samples.append(lab) # add sample name to list so we know which count data goes with which sample
	os.chdir(d)
	for fl in glob.glob("*barseq.log"): # read the barseq.log file for the given sample
		with open(fl) as f:
			f = f.readlines()
		BARseqLines=[]
		for line in f:
			for phrase in parse_BARseq: # only parse the lines related to the numbers we want
				if phrase in line:
					BARseqLines.append(line)
					break
		BARseqLines_parsed=[]	
		for item in BARseqLines:
			BARseqLines_parsed.append(item.split(" ")) # split the lines so that we only get the number

		count=0
		for item in BARseqLines_parsed:
			num=int(item[-1].strip("\n"))
			if (count==0): # must be "Barcodes after filter"
				barcodes_distinct_filtered.append(num)
			elif (count==1): # must be "Barcodes after merge"
				barcodes_distinct_merged.append(num)
			else: # count MUST be 2 so "Sum of all barcode counts"
				barcodes_total_counts_merged.append(num)
			count+=1

	for fl_tag in glob.glob("*logfile.txt"): # read the logfile.txt (ie tagdust output) for the given sample
		with open(fl_tag) as fi:
			fi = fi.readlines()
		tagdustLines=[]
		for line in fi:
			for phrase in parse_tagdust: # only parse lines of interest
				if phrase in line:
					tagdustLines.append(line)
					break

		tagdustLines_parsed=[]
		for item in tagdustLines:
			tagdustLines_parsed.append(item.split("\t")) # split lines so we can get the number we want

		count=0
		for item in tagdustLines_parsed:
			num=int(item[1])
			if (count==0): # must be "total input reads"
				total_reads.append(num)
			else: # count MUST be 1 (must be "successfully extracted")
				total_extracted_reads.append(num)
			count+=1
# save all count data to a dictionary
stats={'Sample_Name': samples, 'total_reads': total_reads, 'total_extracted_reads_tagdust': total_extracted_reads, 'BARSEQ_distinct_bc_filtered': barcodes_distinct_filtered, 'BARSEQ_distinct_bc_merged': barcodes_distinct_merged, 'BARSEQ_total_bc_counts_merged': barcodes_total_counts_merged}	

stats_table=pd.DataFrame.from_dict(stats) # convert dictionary to dataframe for file saving
save_path=cwd+"/barcode_extraction_stats.txt"
#print("save path is")
#print(str(save_path))
stats_table.to_csv(save_path,sep='\t') # save stats table to file
