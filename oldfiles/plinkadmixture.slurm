#!/bin/bash
#SBATCH --job-name=admixture
#SBATCH --time=48:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --account=saarman-np
#SBATCH --partition=saarman-np
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=emily.calhoun@usu.edu

module load plink
module load admixture

VCF_IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_WGS_61samp_stage3_filtered.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_admixture
mkdir -p $OUT_DIR
cd $OUT_DIR

echo "=== ADMIXTURE Pipeline ==="
echo "Start time: $(date)"

# === Step 1: Convert VCF to PLINK bed format ===
echo "Converting VCF to PLINK bed format..."
plink \
    --vcf $VCF_IN \
    --double-id \
    --allow-extra-chr \
    --set-missing-var-ids @:# \
    --make-bed \
    --out Culex_WGS_61samp \
    --threads 8

# ADMIXTURE requires chromosome names to be numeric
# Recode non-numeric chr names to numbers
awk '{$1=0; print $0}' Culex_WGS_61samp.bim > Culex_WGS_61samp_admix.bim
cp Culex_WGS_61samp.bed Culex_WGS_61samp_admix.bed
cp Culex_WGS_61samp.fam Culex_WGS_61samp_admix.fam

echo "Bed file created"
echo "SNPs in bed file:"
wc -l Culex_WGS_61samp_admix.bim
echo "Samples in bed file:"
wc -l Culex_WGS_61samp_admix.fam

# === Step 2: Run ADMIXTURE for K=1 to K=6, 5 replicates each ===
echo ""
echo "Running ADMIXTURE K=1-6, 5 replicates..."

for K in 1 2 3 4 5 6; do
    for REP in 1 2 3 4 5; do
        echo "Running K=${K} replicate ${REP}..."
        admixture \
            --cv \
            -j8 \
            -s ${RANDOM} \
            Culex_WGS_61samp_admix.bed ${K} | \
            tee ${OUT_DIR}/admixture_K${K}_rep${REP}.log
        
        # Rename output files to include replicate number
        mv Culex_WGS_61samp_admix.${K}.Q ${OUT_DIR}/admixture_K${K}_rep${REP}.Q
        mv Culex_WGS_61samp_admix.${K}.P ${OUT_DIR}/admixture_K${K}_rep${REP}.P
    done
done

# === Step 3: Extract CV errors for K selection ===
echo ""
echo "=== Cross-validation errors ==="
echo "K | Rep | CV Error"
for K in 1 2 3 4 5 6; do
    for REP in 1 2 3 4 5; do
        CV=$(grep "CV error" ${OUT_DIR}/admixture_K${K}_rep${REP}.log | awk '{print $4}')
        echo "K=${K} Rep=${REP}: ${CV}"
    done
done

echo ""
echo "=== ADMIXTURE Complete ==="
echo "End time: $(date)"
