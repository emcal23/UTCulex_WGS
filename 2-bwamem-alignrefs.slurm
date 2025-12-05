#!/bin/bash

#SBATCH --partition=saarman-shared-np   
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00   # walltime limit (HH:MM:SS)
#SBATCH --mem=32G
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=16   # 20 processor core(s) per node X 2 threads per core
#SBATCH --job-name="bwamem-ref"
#SBATCH --mail-user=emily.calhoun@usu.edu    # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

# Load modules
module load bwa-mem/2.2.1

# Base folder containing your reference genomes
REFS="/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_bwa/ref"

##########################
# Index Cx pipiens
##########################
cd "$REFS/Cx_pip"

# Rename for simplicity
mv Cpip29_nodeb_gfill_mito.fasta Cx_pipiens.fna

# BWA-MEM2 index
bwa-mem2 index Cx_pipiens.fna


# Permissions
chmod -R g+w /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS*
