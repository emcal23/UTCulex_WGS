#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=48:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --job-name="variant_call"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load samtools
module load bcftools

# Directories
BAM_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_final
REF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_bwa/ref/Cpip29_nodeb_gfill_mito.fasta
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf

mkdir -p "$OUT_DIR"

# Create BAM list with full paths
ls "$BAM_DIR"/*.markdup.bam > "$BAM_DIR/bam_list_for_calling.txt"

echo "=== Starting MINIMAL variant calling ==="
echo "Number of samples: $(cat $BAM_DIR/bam_list_for_calling.txt | wc -l)"
echo "Reference: $REF"
echo "bcftools version: $(bcftools --version | head -1)"

# MINIMAL variant calling - NO fancy annotations
bcftools mpileup \
    -q 30 \
    -Q 30 \
    -d 100 \
    -f "$REF" \
    -b "$BAM_DIR/bam_list_for_calling.txt" \
    -O u | \
bcftools call \
    -m \
    -v \
    -O z \
    -o "$OUT_DIR/Culex_raw_variants.vcf.gz"

# Index the VCF
bcftools index "$OUT_DIR/Culex_raw_variants.vcf.gz"

# Quick stats
echo ""
echo "=== Variant calling complete ==="
echo "Raw VCF: $OUT_DIR/Culex_raw_variants.vcf.gz"
echo ""
bcftools stats "$OUT_DIR/Culex_raw_variants.vcf.gz" | grep "number of SNPs:"
bcftools stats "$OUT_DIR/Culex_raw_variants.vcf.gz" | grep "number of samples:"

echo ""
echo "=========================================="
echo "FILTERS APPLIED:"
echo "  - Min mapping quality: 30"
echo "  - Min base quality: 30"
echo "  - Max depth: 100"
echo "  - Duplicates: skipped (default)"
echo ""
echo "NEXT STEPS:"
echo "  1. This is a basic raw VCF"
echo "  2. Apply Stage 2 filters with your advisor:"
echo "     - Depth filter (DP >= 2x mean)"
echo "     - Missingness filter"
echo "     - MAC filter"
echo "     - Bias filters (if possible)"
echo "=========================================="
