#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=320:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --job-name="variant_call_v2"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load samtools
module load bcftools/1.23

# Directories
BAM_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_finalbams
REF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_bwa/ref/Cpip29_nodeb_gfill_mito.fasta
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf

mkdir -p "$OUT_DIR"

# Create BAM list with full paths
ls "$BAM_DIR"/*.markdup.bam > "$BAM_DIR/bam_list_for_calling.txt"

echo "=== Starting variant calling with bcftools 1.23 ==="
echo "Number of samples: $(cat $BAM_DIR/bam_list_for_calling.txt | wc -l)"
echo "Reference: $REF"
echo "bcftools version: $(bcftools --version | head -1)"

# Call variants with advisor's recommended filters
bcftools mpileup \
    --min-BQ 30 \
    --min-MQ 30 \
    --max-depth 100 \
    --skip-duplicates \
    --threads "$SLURM_CPUS_PER_TASK" \
    --fasta-ref "$REF" \
    --bam-list "$BAM_DIR/bam_list_for_calling.txt" \
    --annotate FORMAT/AD,FORMAT/DP,INFO/AD,INFO/ADF,INFO/ADR \
    --output-type u | \
bcftools call \
    --multiallelic-caller \
    --variants-only \
    --threads "$SLURM_CPUS_PER_TASK" \
    --output-type u | \
bcftools filter \
    --include 'INFO/DP >= 130 && (INFO/RPB > -2 && INFO/RPB < 2 || INFO/RPB == ".") && (INFO/MQB > -2 && INFO/MQB < 2 || INFO/MQB == ".") && (INFO/BQB > -2 && INFO/BQB < 2 || INFO/BQB == ".")' \
    --output-type z \
    --output "$OUT_DIR/Culex_filtered_variants.vcf.gz"

# Index the VCF
bcftools index "$OUT_DIR/Culex_filtered_variants.vcf.gz"

# Quick stats
echo ""
echo "=== Variant calling complete ==="
echo "Filtered VCF: $OUT_DIR/Culex_filtered_variants.vcf.gz"
echo ""
bcftools stats "$OUT_DIR/Culex_filtered_variants.vcf.gz" | grep "number of SNPs:"
bcftools stats "$OUT_DIR/Culex_filtered_variants.vcf.gz" | grep "number of samples:"

echo ""
echo "=========================================="
echo "FILTERS APPLIED:"
echo "  - Min mapping quality: 30 (--min-MQ 30)"
echo "  - Min base quality: 30 (--min-BQ 30)"
echo "  - Max depth: 100 (--max-depth 100)"
echo "  - Duplicates: explicitly skipped (--skip-duplicates)"
echo "  - Min mean depth: 130x (~2x per sample)"
echo "  - Read Position Bias Z-score: -2 to 2"
echo "  - Mapping Quality Bias Z-score: -2 to 2"
echo "  - Base Quality Bias Z-score: -2 to 2"
echo ""
echo "Next: Stage 2 filters (missingness, MAC, etc.)"
echo "=========================================="
