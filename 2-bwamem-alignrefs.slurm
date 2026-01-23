#!/bin/bash

#SBATCH --partition=saarman-np   
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00   # walltime limit (HH:MM:SS)
#SBATCH --mem=64G
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=20   # 20 processor core(s) per node X 2 threads per core
#SBATCH --job-name="bwamem-ref"
#SBATCH --mail-user=emily.calhoun@usu.edu    # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

# Load modules
module load bwa-mem/2.2.1
module load samtools/1.16

# Change to the directory where the input data is located
cd /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_raw


# Run the Perl script with the input files
perl /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_scripts/2b_bwa_mem.pl *.fastq.gz

# Permissions
chmod -R g+w /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS*

# Resource
# https://catchenlab.life.illinois.edu/stacks/manual/#refmapbyhand
