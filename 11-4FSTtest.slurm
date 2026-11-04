#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=00:30:00
#SBATCH --mem=16G
#SBATCH -o FSTtest_%j.out
#SBATCH -e FSTtest_%j.err

module load vcftools
cd ~/saarman-group/Cx_WGS/Cx_WGS_FST/52samp
vcftools --gzvcf ~/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_WGS_53samp_stage3_filtered.vcf.gz \
  --weir-fst-pop pop_BE.txt --weir-fst-pop pop_OGD.txt --out test_BE_OGD
echo "exit code: $?"
ls -l test_BE_OGD*
