#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=1:00:00
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="find_overlap"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools

WGS_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/WGS_21samples_for_ddRAD.vcf.gz
DDRAD_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_filtered/cx_ddRAD_combined2-3_g70m70g20_ABfiltered.p.snps.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged

echo "=== Finding overlapping SNP positions ==="
echo "Start time: $(date)"

# Extract positions
echo "Extracting WGS positions..."
bcftools query -f '%CHROM\t%POS\n' $WGS_VCF > ${OUT_DIR}/wgs_positions_raw.txt

echo "Extracting ddRAD positions..."
bcftools query -f '%CHROM\t%POS\n' $DDRAD_VCF > ${OUT_DIR}/ddrad_positions_raw.txt

# Sort properly (version sort for scaffold names)
echo "Sorting positions..."
sort -V ${OUT_DIR}/wgs_positions_raw.txt > ${OUT_DIR}/wgs_positions_sorted.txt
sort -V ${OUT_DIR}/ddrad_positions_raw.txt > ${OUT_DIR}/ddrad_positions_sorted.txt

# Find intersection using join
echo "Finding shared positions..."
join -t $'\t' ${OUT_DIR}/wgs_positions_sorted.txt ${OUT_DIR}/ddrad_positions_sorted.txt > ${OUT_DIR}/shared_positions.txt

# Cleanup
rm ${OUT_DIR}/wgs_positions_raw.txt ${OUT_DIR}/ddrad_positions_raw.txt

echo ""
echo "=== Position Summary ==="
echo "WGS positions: $(wc -l < ${OUT_DIR}/wgs_positions_sorted.txt)"
echo "ddRAD positions: $(wc -l < ${OUT_DIR}/ddrad_positions_sorted.txt)"
echo "Shared positions: $(wc -l < ${OUT_DIR}/shared_positions.txt)"

echo ""
echo "First 10 shared positions:"
head -10 ${OUT_DIR}/shared_positions.txt

echo ""
echo "=== Complete ==="
echo "End time: $(date)"
