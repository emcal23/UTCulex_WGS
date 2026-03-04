#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=48:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="stage2_bias"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load gatk
module load samtools
module load bcftools

VCF_IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_final_variants.vcf.gz
REF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_bwa/ref/Cpip29_nodeb_gfill_mito.fasta
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf

echo "=== Stage 2: Bias Filtering Only ==="
echo "Input: $VCF_IN"
echo "Start time: $(date)"

# Recompress for GATK
echo "Recompressing VCF for GATK..."
gunzip -c $VCF_IN | bgzip > ${OUT_DIR}/temp_recompressed.vcf.gz
tabix ${OUT_DIR}/temp_recompressed.vcf.gz

# GATK VariantFiltration - ONLY bias filters
echo "Running GATK VariantFiltration (bias Z-scores only)..."
gatk VariantFiltration \
    -R $REF \
    -V ${OUT_DIR}/temp_recompressed.vcf.gz \
    -O ${OUT_DIR}/temp_gatk_filtered.vcf.gz \
    --filter-name "bqbz" --filter-expression "BQBZ > 3.0 || BQBZ < -3.0" \
    --filter-name "mqbz" --filter-expression "MQBZ > 3.0 || MQBZ < -3.0" \
    --filter-name "rpbz" --filter-expression "RPBZ > 3.0 || RPBZ < -3.0"

# Extract PASS variants only
echo "Extracting PASS variants..."
bcftools view -f PASS ${OUT_DIR}/temp_gatk_filtered.vcf.gz \
    -O z -o ${OUT_DIR}/Culex_stage2_bias_filtered.vcf.gz

# Index
bcftools index ${OUT_DIR}/Culex_stage2_bias_filtered.vcf.gz

# Cleanup
rm ${OUT_DIR}/temp_*.vcf.gz*

echo ""
echo "=== Stage 2 Complete ==="
echo "End time: $(date)"
echo "Output: ${OUT_DIR}/Culex_stage2_bias_filtered.vcf.gz"
echo ""
bcftools stats ${OUT_DIR}/Culex_stage2_bias_filtered.vcf.gz | grep "number of SNPs:"
bcftools stats ${OUT_DIR}/Culex_stage2_bias_filtered.vcf.gz | grep "number of samples:"

echo ""
echo "=========================================="
echo "FILTERS APPLIED:"
echo "Stage 1 (during calling):"
echo "  - Min mapping quality: 30"
echo "  - Min base quality: 30"
echo "  - Max depth: 100"
echo "  - Duplicates: skipped"
echo ""
echo "Stage 2 (post-calling):"
echo "  - Base quality bias Z-score: |Z| ≤ 3"
echo "  - Mapping quality bias Z-score: |Z| ≤ 3"
echo "  - Read position bias Z-score: |Z| ≤ 3"
echo ""
echo "NOT YET APPLIED (for Stage 3 forked with ddRAD):"
echo "  - Missingness filters"
echo "  - MAC filters"
echo "  - Location-specific filters"
echo "=========================================="
