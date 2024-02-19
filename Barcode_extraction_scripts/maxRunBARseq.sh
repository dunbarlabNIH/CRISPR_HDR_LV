#!/bin/bash

programname='max $0'
version=0.1

#stop program if an intermediate step fails
set -o pipefail
set -e

# print informative error message upon failure
function fail {
	echo "$@" >&2
	exit 1
}
echo "Program Start Date: $(date)"
#path=$(pwd)
echo
echo "*** YO IT'S VIRTUAL MAX IN THE HOUSE *** Lets go analyze the crap outta some DNA barcodes !!!"
echo "Please enter the FULL PATH to the folder where your run.txt file is located..."
read path
echo "Note in the working directory which you entered above (${path}) you'd better have a file called "run.txt." This program also requires a folder called fastq containing fastq.gz files in the SAME directory as this running script!"
echo

echo "If you would like me to merge old barcode count data, please enter the FULL PATH to the old count table file (eg /data/gricemz/barcodingMAX/M11021072/05_04_22/merge_results/merged_counts.txt), otherwise, please type 'none'"
read merge_old
if [ ! -f "${merge_old}" ] 
then
	if [ "${merge_old}" != "none" ]
	then
		echo "DUDE NO! Either your file path for old count data does not exist or you did not properly enter 'none' as you response to the above question!"
		echo "Exiting program now, check yo self and try again later"
		exit 1
	else
		echo "Looks like this is your first time running! No previous count data will be merged"
	fi
else
	echo "Looks like you've already run some old data before! I'll make sure to merge after the new analysis"
fi

if [ ! -d "fastq" ] 
then
	echo "DUDE NO! fastq folder does not exist, kicking you outta this program..."
	exit 1
fi 
if [ ! -f "${path}/run.txt" ] 
then
	echo "DUDE NO! "run.txt" does not exist, kicking you outta this program..."
	exit 1
fi

numOnames=0 # MUCH BETTER WAY TO COUNT LINES IN A FILE (rather than looking for EOF and skipping last line accidentally)
while read line || [ -n "$line" ] ; do
	((numOnames=numOnames+1))
done < $path/run.txt # count number of commands in run.txt

#echo "Awesome, looks like you've got ${numOnames} new samples you'd like me to analyze! Now you gotta give me the path to your installed tagdust src (for example: /data/gricemz/utils/tagdust-2.33/src)"
tagdust = 'data/utils/tagdust-2.33/src'
#read tagdust
# LOCAL COMPUTER: /Users/gricemz/utils/tagdust-2.33/src
# BIOWULF: /data/gricemz/utils/tagdust-2.33/src

echo "Alrighty almost there, now just a few more parameters I gotta ask about..."
echo "Please enter the edit distance you would like (or 0 if none) for graph based merging of similar barcodes"
read edit_dist
echo "Now enter the saturation threshold for barcodes you would like to keep (default=90)"
read sat
echo "Lastly, enter the minimum count threshold for any given barcode (eg 1)"
read min_count

if [ -d "${path}/output" ] 
then
	echo "DUDE NO! You should not already have a folder called "output" in this directory, please rename and try again..."
	exit 1
fi 
echo
mkdir ${path}/output

while read line || [ -n "$line" ] ; do
	arr=($line)
    name=${arr[0]}
    fastq=${arr[1]}
    s1=${arr[2]}
    s2=${arr[3]}
    barcode=${arr[4]}
    q1='"-1 S:' # because bash has this stupid issue with parsing quotes...
    q2='"'
    q1is0='"-1 R:N'
    none="None"
    if [[ "${s1}" == 0 ]] # if barcode is before an existing sequence (as in lenti vector)
    then
        tag_cmd="${q1is0} -2 S:${s2}${q2}"
	elif [[ "${s2}" == 0 ]] # if barcode is after an existing sequence
	then
		tag_cmd="${q1}${s1} -2 R:N${q2}"
    else
        tag_cmd="${q1}${s1} -2 R:N -3 S:${s2}${q2}" # if barcode is in between two known sequences (as in crispr)
    fi
    mkdir ${path}/output/${name}
    echo "python runBARseq.py -i fastq/${fastq} -tagdust-dir ${tagdust} -tagdust-opt ${tag_cmd} -o ${path}/output/${name} -f fixedstruct -iupac ${barcode} -e ${edit_dist} -s ${sat} -c ${min_count} -t 12"
done < $path/run.txt > swarm.temp

echo "Sweet just finished making the swarm file, do you want me to activate your virtual environment (y for yes and n for no)?"
read activate
if [ ${activate} == y ] ; then
	# COMMENT THE LINES BELOW OUT IF YOU DONT NEED A VIRTUAL ENVIRONMENT
	# instead you can simply use "load module python"
	source /data/$USER/conda/etc/profile.d/conda.sh
	#conda activate base
	conda activate project1
fi
echo 
echo "ALRIGHTY READY TO GO! Submiting the swarm job, you will recieve an email when everything has been completed"
#### EDIT THE LINE BELOW TO CHANGE SWARM SETTINGS ####
jobid=$(swarm --sbatch "--mail-type=BEGIN,END" --time 2-00:00:00 -t 12 -g 20 -f swarm.temp)
echo "Swarm Job ID: ${jobid}..."
echo

sbatch --dependency=afterany:${jobid} run_merge.sh ${merge_old} ${path}
if [ ${activate} == y ] ; then
conda deactivate
fi
