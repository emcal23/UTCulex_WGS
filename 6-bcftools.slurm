#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=320:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --job-name="variant_call_final"
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

echo "=== Starting variant calling ==="
echo "Number of samples: $(cat $BAM_DIR/bam_list_for_calling.txt | wc -l)"
echo "Reference: $REF"
echo "bcftools version: $(bcftools --version | head -1)"
echo "Start time: $(date)"

# Simple variant calling that WORKS
bcftools mpileup \
    --min-BQ 30 \
    --min-MQ 30 \
    --max-depth 100 \
    --threads "$SLURM_CPUS_PER_TASK" \
    --fasta-ref "$REF" \
    --bam-list "$BAM_DIR/bam_list_for_calling.txt" \
    --annotate FORMAT/AD,FORMAT/DP \
    --output-type u | \
bcftools call \
    --multiallelic-caller \
    --variants-only \
    --threads "$SLURM_CPUS_PER_TASK" \
    --output-type z \
    --output "$OUT_DIR/Culex_final_variants.vcf.gz"

# Index the VCF
bcftools index "$OUT_DIR/Culex_final_variants.vcf.gz"

echo ""
echo "=== Variant calling complete ==="
echo "End time: $(date)"
echo "Final VCF: $OUT_DIR/Culex_final_variants.vcf.gz"
echo ""
bcftools stats "$OUT_DIR/Culex_final_variants.vcf.gz" | grep "number of SNPs:"
bcftools stats "$OUT_DIR/Culex_final_variants.vcf.gz" | grep "number of samples:"

echo ""
echo "=========================================="
echo "STAGE 1 FILTERS APPLIED:"
echo "  - Min mapping quality: 30"
echo "  - Min base quality: 30"
echo "  - Max depth: 100"
echo "  - Duplicates: skipped (default)"
echo ""
echo "STAGE 2 FILTERS (to apply next with advisor):"
echo "  - Min mean depth: ~130x (2x per sample)"
echo "  - Missingness filter"
echo "  - MAC filter"
echo "  - Bias filters (RPB/MQB/BQB using vcftools or GATK)"
echo "=========================================="
