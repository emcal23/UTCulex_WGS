#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=12:00:00
#SBATCH --mem=64G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="joint_filter"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools

MERGED=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/merged_WGS_ddRAD.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged

echo "=== Joint Filtering Merged WGS + ddRAD VCF ==="
echo "Start time: $(date)"
echo "Input SNPs: $(bcftools view -H $MERGED | wc -l)"

# Step 1: Remove sites with >50% missingness and MAC > 2
echo "Filtering for missingness and MAF..."
bcftools view $MERGED \
    -i 'F_MISSING < 0.5 && MAC >= 2' \
    -O z -o ${OUT_DIR}/merged_filtered_maf05_miss50.vcf.gz
bcftools index ${OUT_DIR}/merged_filtered_maf05_miss50.vcf.gz

echo "After missingness + MAF filter: $(bcftools view -H ${OUT_DIR}/merged_filtered_maf05_miss50.vcf.gz | wc -l) SNPs"

# Step 2: Remove genotypes with depth < 3 (set to missing)
echo "Filtering low depth genotypes..."
bcftools filter \
    -S . \
    -e 'FMT/DP < 3' \
    ${OUT_DIR}/merged_filtered_maf05_miss50.vcf.gz \
    -O z -o ${OUT_DIR}/merged_filtered_final.vcf.gz
bcftools index ${OUT_DIR}/merged_filtered_final.vcf.gz

echo ""
echo "=== Filtering Summary ==="
echo "Input SNPs:  44263515"
echo "After MAF + missingness filter: $(bcftools view -H ${OUT_DIR}/merged_filtered_maf05_miss50.vcf.gz | wc -l)"
echo "Final SNPs: $(bcftools view -H ${OUT_DIR}/merged_filtered_final.vcf.gz | wc -l)"
echo "Final samples: $(bcftools query -l ${OUT_DIR}/merged_filtered_final.vcf.gz | wc -l)"

echo "Done! End time: $(date)"
