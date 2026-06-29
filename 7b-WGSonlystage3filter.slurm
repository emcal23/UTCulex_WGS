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
module load htslib

VCF_IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_stage2_bias_filtered.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf
PREFIX=Culex_WGS_61samp

echo "=== Stage 3: SNP Filtering ==="
echo "Input: $VCF_IN"
echo "Start time: $(date)"

echo "SNPs before stage 3:"
bcftools stats $VCF_IN | grep "number of SNPs:"
echo "Samples in input VCF:"
bcftools query -l $VCF_IN | wc -l

vcftools --gzvcf $VCF_IN \
    --max-missing 0.80 \
    --mac 3 \
    --min-alleles 2 \
    --max-alleles 2 \
    --remove-indels \
    --recode --stdout | \
    bgzip > ${OUT_DIR}/${PREFIX}_stage3_filtered.vcf.gz

bcftools index ${OUT_DIR}/${PREFIX}_stage3_filtered.vcf.gz

echo ""
echo "=== Stage 3 Complete ==="
echo "End time: $(date)"
echo ""
echo "SNPs after stage 3:"
bcftools stats ${OUT_DIR}/${PREFIX}_stage3_filtered.vcf.gz | grep "number of SNPs:"
bcftools stats ${OUT_DIR}/${PREFIX}_stage3_filtered.vcf.gz | grep "number of samples:"
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
echo ""
echo "Stage 3 (this script):"
echo "  - Max missingness: 20% per SNP (--max-missing 0.8)"
echo "  - Min MAC: 3"
echo "  - Biallelic SNPs only"
echo "  - No indels"
echo "=========================================="
