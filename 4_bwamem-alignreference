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
module load samtools/1.17

# Base folder containing your reference genomes
REFS="/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/refs_CxWGS"

##########################
# Index Cx pipiens
##########################
cd "$REFS/Cx_pip"

# Rename for simplicity
mv GCA_041146695.1_INRAE_Cpip_1_genomic.fna Cx_pipiens.fna
mv GCA_041146695.1_INRAE_Cpip_1_genomic.gff Cx_pipiens.gff

# BWA-MEM2 index
bwa-mem2 index Cx_pipiens.fna

# Samtools FASTA index
samtools faidx Cx_pipiens.fna

##########################
# Index Cx quinquefasciatus
##########################
cd "$REF_BASE/Cx_quinq"

# Rename for simplicity
mv GCF_000209185.1_Cx_quinquefasciatus_genomic.fna Cx_quinq.fna
mv GCF_000209185.1_Cx_quinquefasciatus_genomic.gff Cx_quinq.gff

# BWA-MEM2 index
bwa-mem2 index Cx_quinq.fna

# Samtools FASTA index
samtools faidx Cx_quinq.fna

# Permissions
chmod -R g+w /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS*
