#!/bin/bash

# job standard output will go to the file slurm-%j.out (where %j is the job ID)

#SBATCH --partition=saarman-shared-np   
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00   # walltime limit (HH:MM:SS)
#SBATCH --mem=24576 # memory given in MB
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=16   # 20 processor core(s) per node X 2 threads per core
#SBATCH --job-name="download"
#SBATCH --mail-user=emily.calhoun@usu.edu    # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

# LOAD MODULES, INSERT CODE, AND RUN YOUR PROGRAMS HERE

# Load modules
module load bwa/2020_03_19

# Replace these variables with the actual paths and filenames
# input_folder="/uufs/chpc.utah.edu/common/home/saarman-group1/cx_ddRAD_processed/"
output_folder="/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/refs_CxWGS"

# Download reference
cd $output_folder
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/041/146/695/GCA_041146695.1_INRAE_Cpip_1/GCA_041146695.1_INRAE_Cpip_1_genomic.fna.gz
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/041/146/695/GCA_041146695.1_INRAE_Cpip_1/GCA_041146695.1_INRAE_Cpip_1_genomic.gff.gz
gunzip *.gz

#Reference already here
Pipref="/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/refs_CxWGS/" 
Quinqref="/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/refs_CxWGS/" 

# Permissions
chmod -R g+w /uufs/chpc.utah.edu/common/home/saarman-group1/cx_ddRAD*

# Unzip reference if needed
# gzip -d GCF_003710045.2_USU_Nmel_1.3_genomic.fna.gz 

# Permissions
chmod -R g+w /uufs/chpc.utah.edu/common/home/saarman-group1/cx_ddRAD*
