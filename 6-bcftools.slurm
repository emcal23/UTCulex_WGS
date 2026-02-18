#!/bin/bash

#SBATCH --partition=saarman-np   
#SBATCH --account=saarman-np
#SBATCH --time=72:00:00   # walltime limit 336 (HH:MM:SS)
#SBATCH --mem=64G
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=20   # 20 processor core(s) per node X 2 threads per core
#SBATCH --job-name="bcftools-variantcalling"
#SBATCH --mail-user=emily.calhoun@usu.edu    # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

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
    --skip-duplicates \
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
echo "Next: Wait for advisor's guidance on Stage 2 filtering (missingness, MAC, AB)"
