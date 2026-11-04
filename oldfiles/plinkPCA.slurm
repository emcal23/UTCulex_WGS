#!/bin/bash
#SBATCH --job-name=plink_pca
#SBATCH --time=2:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --account=saarman-np
#SBATCH --partition=saarman-np
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=emily.calhoun@usu.edu

module load plink

VCF_IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_WGS_61samp_stage3_filtered_LDpruned.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_pca
PREFIX=Culex_WGS_61samp_pca_LDpruned

mkdir -p $OUT_DIR

echo "=== PLINK PCA — LD-pruned ==="
echo "Input: $VCF_IN"
echo "Start time: $(date)"

plink \
    --vcf $VCF_IN \
    --double-id \
    --allow-extra-chr \
    --set-missing-var-ids @:# \
    --pca 10 \
    --out ${OUT_DIR}/${PREFIX} \
    --threads 8

echo ""
echo "=== PCA Complete ==="
echo "End time: $(date)"
echo ""
echo "Output files:"
ls -lh ${OUT_DIR}/${PREFIX}.*
