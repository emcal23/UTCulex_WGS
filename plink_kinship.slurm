#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=12:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --job-name="kinship"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL


module load plink

VCF_IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_WGS_61samp_stage3_filtered_LDpruned.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_kinship
PREFIX=Culex_WGS_61samp_kinship

mkdir -p $OUT_DIR

echo "=== PLINK Kinship / IBD Estimation ==="
echo "Input: $VCF_IN"
echo "Start time: $(date)"

plink \
    --vcf $VCF_IN \
    --double-id \
    --allow-extra-chr \
    --set-missing-var-ids @:# \
    --genome \
    --out ${OUT_DIR}/${PREFIX} \
    --threads 8

echo ""
echo "=== Kinship Complete ==="
echo "End time: $(date)"
echo ""
echo "Output files:"
ls -lh ${OUT_DIR}/${PREFIX}.*
