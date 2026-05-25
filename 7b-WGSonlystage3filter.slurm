#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="stage3_filter"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools
module load vcftools

VCF_IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_stage2_bias_filtered.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf
PREFIX=Culex_WGS_65samp

echo "=== Stage 3: SNP Filtering ==="
echo "Input: $VCF_IN"
echo "Start time: $(date)"

# Check sample count going in
echo "Samples in input VCF:"
bcftools query -l $VCF_IN | wc -l

vcftools --gzvcf $VCF_IN \
    --max-missing 0.80 \     # Keep SNPs present in ≥80% of samples
    --mac 3 \                # Minor allele count ≥3
    --min-alleles 2 \
    --max-alleles 2 \        # Biallelic SNPs only
    --remove-indels \        # SNPs only, no indels
    --recode --stdout | \
    bgzip > ${OUT_DIR}/${PREFIX}_stage3.vcf.gz

bcftools index ${OUT_DIR}/${PREFIX}_stage3.vcf.gz

echo ""
echo "=== Stage 3 Complete ==="
echo "End time: $(date)"
echo ""
bcftools stats ${OUT_DIR}/${PREFIX}_stage3.vcf.gz | grep "number of SNPs:"
bcftools stats ${OUT_DIR}/${PREFIX}_stage3.vcf.gz | grep "number of samples:"
echo ""
echo "=========================================="
echo "ALL FILTERS APPLIED (cumulative):"
echo "Stage 1 (during calling):"
echo "  - Min mapping quality: 30"
echo "  - Min base quality: 30"
echo "  - Max depth: 100"
echo "  - Duplicates: skipped"
echo ""
echo "Stage 2 (bias):"
echo "  - BQBZ, MQBZ, RPBZ: |Z| <= 3"
echo " -then some pulled to merge with ddRAD"
echo "Stage 3 (this script):"
echo "  - Max missingness: 20% per SNP"
echo "  - Min MAC: 3"
echo "  - Biallelic SNPs only"
echo "  - No indels"
echo "=========================================="
