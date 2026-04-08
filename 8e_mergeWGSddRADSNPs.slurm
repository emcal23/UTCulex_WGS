#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=1:00:00
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="merge_vcfs"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools

WGS_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/WGS_shared_snps.vcf.gz
DDRAD_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/ddRAD_shared_snps.vcf.gz
REF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_bwa/ref/Cpip29_nodeb_gfill_mito.fasta
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged

echo "=== Normalizing and merging VCFs ==="
echo "Start time: $(date)"

# Normalize WGS VCF (check REF alleles against reference)
echo "Normalizing WGS VCF..."
bcftools norm -f $REF -c s $WGS_VCF \
    -O z -o ${OUT_DIR}/WGS_shared_normalized.vcf.gz
bcftools index ${OUT_DIR}/WGS_shared_normalized.vcf.gz

# Normalize ddRAD VCF (check REF alleles against reference)
echo "Normalizing ddRAD VCF..."
bcftools norm -f $REF -c s $DDRAD_VCF \
    -O z -o ${OUT_DIR}/ddRAD_shared_normalized.vcf.gz
bcftools index ${OUT_DIR}/ddRAD_shared_normalized.vcf.gz

# Now merge normalized VCFs
echo ""
echo "Merging normalized VCFs..."
bcftools merge \
    ${OUT_DIR}/WGS_shared_normalized.vcf.gz \
    ${OUT_DIR}/ddRAD_shared_normalized.vcf.gz \
    -O z -o ${OUT_DIR}/merged_WGS_ddRAD_raw.vcf.gz

# Index merged VCF
echo "Indexing merged VCF..."
bcftools index ${OUT_DIR}/merged_WGS_ddRAD_raw.vcf.gz

echo ""
echo "=== Merge Complete ==="
echo "End time: $(date)"

# Check the merged VCF
echo ""
echo "Merged VCF stats:"
bcftools stats ${OUT_DIR}/merged_WGS_ddRAD_raw.vcf.gz | grep "number of samples:"
bcftools stats ${OUT_DIR}/merged_WGS_ddRAD_raw.vcf.gz | grep "number of SNPs:"

echo ""
echo "First 5 WGS samples:"
bcftools query -l ${OUT_DIR}/merged_WGS_ddRAD_raw.vcf.gz | head -5

echo ""
echo "First 5 ddRAD samples:"
bcftools query -l ${OUT_DIR}/merged_WGS_ddRAD_raw.vcf.gz | tail -150 | head -5

echo ""
echo "Output file: ${OUT_DIR}/merged_WGS_ddRAD_raw.vcf.gz"
echo ""
echo "Next step: Filter for missingness and MAC!"
