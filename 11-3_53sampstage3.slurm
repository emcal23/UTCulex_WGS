#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00
#SBATCH --mem=32000
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --job-name="53samp"
#SBATCH -o 53samp_%j.out
#SBATCH -e 53samp_%j.err

cd /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf

module load bcftools
module load vcftools
module load htslib
module load plink/1.90

# 1. Clean sample names on the Stage 2 VCF
bcftools reheader -s rename_map.txt -o Culex_WGS_61samp_stage2_renamed.vcf.gz Culex_WGS_61samp_stage2_samplefiltered.vcf.gz
echo "Stage 2 names after rename:"
bcftools query -l Culex_WGS_61samp_stage2_renamed.vcf.gz | head -3

# 2. Drop the 8 artifact samples
bcftools view -S ^drop8_artifact.txt Culex_WGS_61samp_stage2_renamed.vcf.gz -Oz -o Culex_WGS_53samp_stage2.vcf.gz --threads 8
echo "Samples remaining:"
bcftools query -l Culex_WGS_53samp_stage2.vcf.gz | wc -l

# 3. Stage 3 filters (same as 7b-WGSonlystage3filter.slurm), recalculated on 53 samples
vcftools --gzvcf Culex_WGS_53samp_stage2.vcf.gz \
    --max-missing 0.80 \
    --mac 3 \
    --min-alleles 2 \
    --max-alleles 2 \
    --remove-indels \
    --recode --stdout | \
    bgzip > Culex_WGS_53samp_stage3_filtered.vcf.gz
bcftools index -t Culex_WGS_53samp_stage3_filtered.vcf.gz
echo "SNPs after Stage 3:"
bcftools view -H Culex_WGS_53samp_stage3_filtered.vcf.gz | wc -l

# 4. Depth + PCA on the new dataset
vcftools --gzvcf Culex_WGS_53samp_stage3_filtered.vcf.gz --depth --out Culex_WGS_53samp_depth
plink --vcf Culex_WGS_53samp_stage3_filtered.vcf.gz --allow-extra-chr --double-id \
      --pca 10 --het --out Culex_WGS_53samp_pca
