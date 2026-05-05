#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=12:00:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="normalize_merge"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools

REF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_bwa/ref/Cpip29_nodeb_gfill_mito.fasta
WGS_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/WGS_21samples_for_ddRAD.vcf.gz
DDRAD_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_populations_formerge/populations.snps.sorted.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged

echo "=== Normalizing and Merging WGS and ddRAD VCFs ==="
echo "Start time: $(date)"

# Normalize WGS VCF
echo "Normalizing WGS VCF..."
bcftools norm -f $REF -m -any $WGS_VCF -O z -o ${OUT_DIR}/WGS_normalized.vcf.gz
bcftools index ${OUT_DIR}/WGS_normalized.vcf.gz

# Normalize ddRAD VCF
echo "Normalizing ddRAD VCF..."
bcftools norm -f $REF -m -any $DDRAD_VCF -O z -o ${OUT_DIR}/ddRAD_normalized.vcf.gz
bcftools index ${OUT_DIR}/ddRAD_normalized.vcf.gz

# Merge normalized VCFs
echo "Merging..."
bcftools merge \
    --merge snps \
    -O z \
    -o ${OUT_DIR}/merged_WGS_ddRAD.vcf.gz \
    ${OUT_DIR}/WGS_normalized.vcf.gz \
    ${OUT_DIR}/ddRAD_normalized.vcf.gz

# Index output
echo "Indexing merged VCF..."
bcftools index ${OUT_DIR}/merged_WGS_ddRAD.vcf.gz

echo ""
echo "=== Merge Summary ==="
echo "Samples in merged VCF: $(bcftools query -l ${OUT_DIR}/merged_WGS_ddRAD.vcf.gz | wc -l)"
echo "SNPs in merged VCF: $(bcftools view -H ${OUT_DIR}/merged_WGS_ddRAD.vcf.gz | wc -l)"

echo "Done! End time: $(date)"
