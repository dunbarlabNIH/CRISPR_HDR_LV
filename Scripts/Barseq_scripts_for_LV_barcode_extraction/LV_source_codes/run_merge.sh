#!/bin/bash
#stop program if an intermediate step fails
set -o pipefail
set -e
# print informative error message upon failure
function fail {
	echo "$@" >&2
	exit 1
}
export TMPDIR=/lscratch/$SLURM_JOB_ID
path=$2

echo "Path is $2"
echo "Merge option for R is $1"
echo
cwd=$(pwd)

if [ ! -d "${path}/output" ] 
then
	echo "No output folder from BARseq exists in ${path}/output, exiting program now..."
	exit 1
fi

if [ -d "${path}/merge_results" ] 
then
	echo "merge barcodes has been run before, MOVE FOLDER TO NEW LOCATION/SUBFOLDER BEFORE RUNNING..."
	exit 1
	#rm -r ${path}/merge_results
fi

if [ ! -d "${path}/swarm" ] 
then
	echo "Cleaning up swarm files..."
	mkdir ${path}/swarm
	mv ${cwd}/swarm_* ${path}/swarm
	mv ${cwd}/swarm.temp ${path}/swarm
fi

module load python
python get_stats.py ${path}

module load R
if [ $1 != "none" ]
then
	echo "Running Rscript to merge old and new count files together!"
	Rscript merge_OLDandNEW.R $1 $2
else
	echo "Running Rscript only to merge new data"
	Rscript merge.R $2
fi
