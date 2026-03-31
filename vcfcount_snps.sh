#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=1:00:00
#SBATCH --mem=4G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --job-name="count_snps"

module load bcftools

VCF_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf

echo "Counting SNPs in Stage 1 VCF..."
bcftools view -H ${VCF_DIR}/Culex_final_variants.vcf.gz | wc -l

echo ""
echo "Counting SNPs in Stage 2 VCF..."
bcftools view -H ${VCF_DIR}/Culex_stage2_bias_filtered.vcf.gz | wc -l

echo ""
echo "Done!"
