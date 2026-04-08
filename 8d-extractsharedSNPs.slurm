#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=1:00:00
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="extract_shared"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools

WGS_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/WGS_21samples_for_ddRAD.vcf.gz
DDRAD_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_filtered/cx_ddRAD_combined2-3_g70m70g20_ABfiltered.p.snps.vcf.gz
SHARED_POS=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/shared_positions.txt
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged

echo "=== Extracting shared SNPs from each VCF ==="
echo "Start time: $(date)"

# Extract shared positions from WGS VCF
echo "Extracting 784 shared SNPs from WGS (21 samples)..."
bcftools view -R $SHARED_POS $WGS_VCF \
    -O z -o ${OUT_DIR}/WGS_shared_snps.vcf.gz

# Index WGS output
bcftools index ${OUT_DIR}/WGS_shared_snps.vcf.gz

# Extract shared positions from ddRAD VCF
echo "Extracting 784 shared SNPs from ddRAD (180 samples)..."
bcftools view -R $SHARED_POS $DDRAD_VCF \
    -O z -o ${OUT_DIR}/ddRAD_shared_snps.vcf.gz

# Index ddRAD output
bcftools index ${OUT_DIR}/ddRAD_shared_snps.vcf.gz

echo ""
echo "=== Extraction Complete ==="
echo "End time: $(date)"

# Verify outputs
echo ""
echo "WGS subset:"
bcftools stats ${OUT_DIR}/WGS_shared_snps.vcf.gz | grep "number of samples:"
bcftools stats ${OUT_DIR}/WGS_shared_snps.vcf.gz | grep "number of SNPs:"

echo ""
echo "ddRAD subset:"
bcftools stats ${OUT_DIR}/ddRAD_shared_snps.vcf.gz | grep "number of samples:"
bcftools stats ${OUT_DIR}/ddRAD_shared_snps.vcf.gz | grep "number of SNPs:"

echo ""
echo "Files created:"
echo "  ${OUT_DIR}/WGS_shared_snps.vcf.gz"
echo "  ${OUT_DIR}/ddRAD_shared_snps.vcf.gz"
echo ""
echo "Ready for merging!"
