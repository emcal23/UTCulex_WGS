#!/bin/bash

#SBATCH --partition=saarman-np   
#SBATCH --account=saarman-np
#SBATCH --time=72:00:00   # walltime limit 336 (HH:MM:SS)
#SBATCH --mem=64G
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=20   # 20 processor core(s) per node X 2 threads per core
#SBATCH --job-name="bcftools-variantcalling"
#SBATCH --mail-user=emily.calhoun@usu.edu    # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL



bcftools mpileup --skip-duplicates -f reference.fasta sample.markdup.bam | \
bcftools call -mv -Oz -o sample.vcf.gz
