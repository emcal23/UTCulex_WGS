#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=2:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --job-name="ld_thin"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools

IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/merged_filtered_final.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged

echo "=== LD Thinning ==="
echo "Start time: $(date)"
echo "Input SNPs: $(bcftools view -H $IN | wc -l)"

# Keep 1 SNP per 1000bp window
bcftools +prune \
    -w 1000bp \
    --nsites-per-win 1 \
    $IN \
    -O z -o ${OUT_DIR}/merged_filtered_thinned.vcf.gz

bcftools index ${OUT_DIR}/merged_filtered_thinned.vcf.gz

echo "SNPs after thinning: $(bcftools view -H ${OUT_DIR}/merged_filtered_thinned.vcf.gz | wc -l)"
echo "Samples retained: $(bcftools query -l ${OUT_DIR}/merged_filtered_thinned.vcf.gz | wc -l)"
echo "Done! End time: $(date)"
