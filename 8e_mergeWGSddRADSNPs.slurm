#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=12:00:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="merge_WGS_ddRAD"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools

WGS_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/WGS_21samples_for_ddRAD.vcf.gz
DDRAD_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_populations_formerge/populations.snps.sorted.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged
REGIONS=${OUT_DIR}/shared_positions.txt

echo "=== Merging WGS and ddRAD VCFs ==="
echo "Start time: $(date)"

# Convert shared positions to bcftools regions format
echo "Preparing regions file..."
awk '{print $1":"$2"-"$2}' $REGIONS > ${OUT_DIR}/shared_regions.txt

# Merge on shared positions only
echo "Merging..."
bcftools merge \
    --regions-file ${OUT_DIR}/shared_regions.txt \
    --merge snps \
    -O z \
    -o ${OUT_DIR}/merged_WGS_ddRAD.vcf.gz \
    $WGS_VCF $DDRAD_VCF

# Index the output
echo "Indexing merged VCF..."
bcftools index ${OUT_DIR}/merged_WGS_ddRAD.vcf.gz

echo ""
echo "=== Merge Summary ==="
echo "Samples in merged VCF: $(bcftools query -l ${OUT_DIR}/merged_WGS_ddRAD.vcf.gz | wc -l)"
echo "SNPs in merged VCF: $(bcftools view -H ${OUT_DIR}/merged_WGS_ddRAD.vcf.gz | wc -l)"

echo "Done! End time: $(date)"
