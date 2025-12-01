#!/bin/bash

#SBATCH --partition=saarman-shared-np   
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00   # walltime limit (HH:MM:SS)
#SBATCH --mem=24576 # memory given in MB
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=16   # 20 processor core(s) per node X 2 threads per core
#SBATCH --job-name="fastqc"
#SBATCH --array=0-129%40
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=emily.calhoun@usu.edu

module load fastqc/0.12.1

# Directories
input_folder="/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_raw"
output_folder="/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/fastQC_WGS_Cx"

# Make output directory if missing
mkdir -p "$output_folder"

# List all FASTQ files into an array
FASTQS=($(ls $input_folder/*.fastq.gz))

# Select the file for this array task
FILE=${FASTQS[$SLURM_ARRAY_TASK_ID]}

echo "Running FastQC on: $FILE"

fastqc "$FILE" --outdir="$output_folder"

echo "Done: $FILE"
