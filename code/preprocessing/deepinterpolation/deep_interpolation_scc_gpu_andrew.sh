#!/bin/bash -l

#specify array job
#superseded by sub_deep
# -t 1-14

#this makes it so you'll get an email at the (b)eginning of the job, (e)nd of the job, and on an (a)bort of the job
#$ -m abe

#this merges output and error files into one file
#$ -j y

#this sets the project for the script to be run under
#$ -P jchenlab

#Specify number of GPUs
#$ -l gpus=1

#Specify GPU Type
#$ -l gpu_c=7.0

anm=$1
sess=$2

module load miniconda
conda activate deepinterpolation
module load tensorflow

cd ~/deepinterpolation/

python inference_GPU_SCC.py $anm $sess
