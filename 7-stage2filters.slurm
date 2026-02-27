#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=6:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="stage2_filter"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load gatk
module load samtools
module load bcftools
module load vcftools

VCF_IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_final_variants.vcf.gz
REF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_bwa/ref/Cpip29_nodeb_gfill_mito.fasta
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf

echo "=== Stage 2 Filtering ==="
echo "Input: $VCF_IN"
echo "Start time: $(date)"

# Step 1: Recompress for GATK compatibility
echo "Step 1: Recompressing VCF for GATK..."
gunzip -c $VCF_IN | bgzip > ${OUT_DIR}/temp_recompressed.vcf.gz
tabix ${OUT_DIR}/temp_recompressed.vcf.gz

# Step 2: GATK VariantFiltration (calculates and filters bias Z-scores)
echo "Step 2: Running GATK VariantFiltration (bias filters)..."
gatk VariantFiltration \
    -R $REF \
    -V ${OUT_DIR}/temp_recompressed.vcf.gz \
    -O ${OUT_DIR}/temp_gatk_filtered.vcf.gz \
    --filter-name "bqbz" --filter-expression "BQBZ > 3.0 || BQBZ < -3.0" \
    --filter-name "mqbz" --filter-expression "MQBZ > 3.0 || MQBZ < -3.0" \
    --filter-name "rpbz" --filter-expression "RPBZ > 3.0 || RPBZ < -3.0" \
    --filter-name "depth" --filter-expression "DP < 130" \
    --filter-name "mapping" --filter-expression "MQ < 30"

# Step 3: Keep only PASS variants (remove filtered ones)
echo "Step 3: Extracting PASS variants..."
bcftools view -f PASS ${OUT_DIR}/temp_gatk_filtered.vcf.gz -O z -o ${OUT_DIR}/temp_gatk_pass.vcf.gz

# Step 4: vcftools for missingness and MAC
echo "Step 4: Applying missingness and MAC filters..."
vcftools --gzvcf ${OUT_DIR}/temp_gatk_pass.vcf.gz \
    --max-missing 0.8 \
    --mac 2 \
    --recode --stdout | bgzip > ${OUT_DIR}/Culex_stage2_filtered.vcf.gz

# Index final file
bcftools index ${OUT_DIR}/Culex_stage2_filtered.vcf.gz

# Cleanup temp files
echo "Cleaning up temporary files..."
rm ${OUT_DIR}/temp_*.vcf.gz*

# Stats
echo ""
echo "=== Stage 2 Filtering Complete ==="
echo "End time: $(date)"
echo "Final filtered VCF: ${OUT_DIR}/Culex_stage2_filtered.vcf.gz"
echo ""
echo "Variant counts:"
bcftools stats ${OUT_DIR}/Culex_stage2_filtered.vcf.gz | grep "number of SNPs:"
bcftools stats ${OUT_DIR}/Culex_stage2_filtered.vcf.gz | grep "number of samples:"

echo ""
echo "=========================================="
echo "ALL FILTERS APPLIED:"
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
echo "  - Min total depth: 130x (~2x per sample)"
echo "  - Min mapping quality: 30"
echo "  - Max missingness: 20% (keep if in ≥80% samples)"
echo "  - Min minor allele count: 2"
echo "=========================================="
