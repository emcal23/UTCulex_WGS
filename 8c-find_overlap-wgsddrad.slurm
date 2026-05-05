#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=1:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="find_overlap"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools

WGS_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/WGS_21samples_for_ddRAD.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged
DDRAD_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_populations_formerge/populations.snps.vcf.gz
#DDRAD_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_filtered/cx_ddRAD_combined2-3_g70m70g20_ABfiltered.p.snps.vcf.gz

echo "=== Finding overlapping SNP positions ==="
echo "Start time: $(date)"

# Extract positions
echo "Extracting WGS positions..."
bcftools query -f '%CHROM\t%POS\n' $WGS_VCF > ${OUT_DIR}/wgs_positions.txt

echo "Extracting ddRAD positions..."
bcftools query -f '%CHROM\t%POS\n' $DDRAD_VCF > ${OUT_DIR}/ddrad_positions.txt

# Use awk to find exact CHROM+POS matches
echo "Finding shared positions (this may take a few minutes)..."
awk 'NR==FNR{a[$1"\t"$2]; next} ($1"\t"$2) in a' \
    ${OUT_DIR}/ddrad_positions.txt \
    ${OUT_DIR}/wgs_positions.txt \
    > ${OUT_DIR}/shared_positions.txt

echo ""
echo "=== Position Summary ==="
echo "WGS positions: $(wc -l < ${OUT_DIR}/wgs_positions.txt)"
echo "ddRAD positions: $(wc -l < ${OUT_DIR}/ddrad_positions.txt)"
echo "Shared positions: $(wc -l < ${OUT_DIR}/shared_positions.txt)"

echo ""
echo "First 10 shared positions:"
head -10 ${OUT_DIR}/shared_positions.txt

echo ""
echo "Last 10 shared positions:"
tail -10 ${OUT_DIR}/shared_positions.txt

echo ""
echo "=== Complete ==="
echo "End time: $(date)"
echo "Shared positions saved to: ${OUT_DIR}/shared_positions.txt"
