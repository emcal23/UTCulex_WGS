#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=5:00:00
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="find_overlap"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools

WGS_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/WGS_21samples_for_ddRAD.vcf.gz
DDRAD_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_filtered/cx_ddRAD_combined2-3_g70m70g20_ABfiltered.p.snps.vcf
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged

echo "=== Finding overlapping SNP positions ==="
echo "Start time: $(date)"

# Get positions from WGS (CHROM + POS)
echo "Extracting WGS positions..."
bcftools query -f '%CHROM\t%POS\n' $WGS_VCF | sort -k1,1 -k2,2n > ${OUT_DIR}/wgs_positions.txt

# Get positions from ddRAD (CHROM + POS)
echo "Extracting ddRAD positions..."
bcftools query -f '%CHROM\t%POS\n' $DDRAD_VCF | sort -k1,1 -k2,2n > ${OUT_DIR}/ddrad_positions.txt

# Find shared positions (intersection)
echo "Finding shared positions..."
comm -12 ${OUT_DIR}/wgs_positions.txt ${OUT_DIR}/ddrad_positions.txt > ${OUT_DIR}/shared_positions.txt

echo ""
echo "=== Position Summary ==="
echo "WGS positions: $(wc -l < ${OUT_DIR}/wgs_positions.txt)"
echo "ddRAD positions: $(wc -l < ${OUT_DIR}/ddrad_positions.txt)"
echo "Shared positions: $(wc -l < ${OUT_DIR}/shared_positions.txt)"

echo ""
echo "=== Complete ==="
echo "End time: $(date)"
echo "Shared positions saved to: ${OUT_DIR}/shared_position
