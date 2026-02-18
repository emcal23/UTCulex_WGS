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
    -q 30 \
    -Q 30 \
    -d 100 \
    --threads "$SLURM_CPUS_PER_TASK" \
    -f "$REF" \
    -b "$BAM_DIR/bam_list_for_calling.txt" \
    -a FORMAT/AD,FORMAT/DP,INFO/AD,INFO/ADF,INFO/ADR,INFO/SCR \
    -O u | \
bcftools call \
    -m \
    -v \
    --threads "$SLURM_CPUS_PER_TASK" \
    -a INFO/SCR \
    -O u | \
bcftools filter \
    -i 'INFO/DP >= 2' \
    -O z \
    -o "$OUT_DIR/Culex_raw_variants.vcf.gz"

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
echo "Filters applied during calling:"
echo "  - Duplicates skipped (default: --ns UNMAP,SECONDARY,QCFAIL,DUP)"
echo "  - Min mapping quality: 30 (-q 30)"
echo "  - Min base quality: 30 (-Q 30)"  
echo "  - Max depth per file: 100 (-d 100)"
echo "  - Min mean depth across samples: 2x (INFO/DP >= 2)"
echo ""
echo "Note: RPB, MQB, BQB bias statistics require newer bcftools or different annotation flags."

echo "Next: Apply Stage 2 filters (missingness, MAC, allele balance, etc.)"
