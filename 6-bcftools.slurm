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

echo "=== Starting variant calling ==="
echo "Number of samples: $(cat $BAM_DIR/bam_list_for_calling.txt | wc -l)"
echo "Reference: $REF"

# Call variants across ALL samples
bcftools mpileup \
    --min-BQ 30 \
    --min-MQ 30 \
    --max-depth 100 \
    --excl-flags DUP \
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
    --include 'INFO/DP >= 2 && (INFO/RPB > -2 && INFO/RPB < 2 || INFO/RPB == ".") && (INFO/MQB > -2 && INFO/MQB < 2 || INFO/MQB == ".") && (INFO/BQB > -2 && INFO/BQB < 2 || INFO/BQB == ".")' \
    --output-type z \
    --output "$OUT_DIR/Culex_raw_variants.vcf.gz"

# Index the VCF
bcftools index "$OUT_DIR/Culex_raw_variants.vcf.gz"

# Quick stats
echo ""
echo "=== Variant calling complete ==="
echo "Raw VCF: $OUT_DIR/Culex_raw_variants.vcf.gz"
echo ""
echo "Quick stats:"
bcftools stats "$OUT_DIR/Culex_raw_variants.vcf.gz" | grep "number of SNPs:"
bcftools stats "$OUT_DIR/Culex_raw_variants.vcf.gz" | grep "number of samples:"

echo ""
echo "Filters applied:"
echo "  - Skip dups / Excluded duplicate-flagged reads (--excl-flags DUP)"
echo "  - Min mean depth: 2x (INFO/DP >= 2)"
echo "  - Read Position Bias Z-score: -2 to 2 (RPB)"
echo "  - Mapping Quality Bias Z-score: -2 to 2 (MQB)"
echo "  - Base Quality Bias Z-score: -2 to 2 (BQB)"
echo ""
echo "Next: Apply Stage 2 filters (missingness, MAC, etc.)"
