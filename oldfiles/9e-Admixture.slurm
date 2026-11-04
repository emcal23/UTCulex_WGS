#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=12:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --job-name="admixture_K2-5"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load plink/1.90
module load admixture/1.3.0

VCF=/uufs/chpc.utah.edu/common/home/saarman-group1/Cx_WGS/Cx_WGS_ddRAD_merged/vcf_filtered/merged_WGS_ddRAD_g70m70g05_ABfiltered_LDpruned.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/saarman-group1/Cx_WGS/Cx_WGS_ddRAD_merged/admixture
mkdir -p $OUT_DIR
cd $OUT_DIR

echo "=== Step 1: VCF to PLINK binary format ==="
echo "Start: $(date)"

plink --vcf $VCF \
    --make-bed \
    --allow-extra-chr \
    --set-missing-var-ids @:# \
    --double-id \
    --out merged_admixture_input

echo "PLINK conversion done: $(date)"

echo "=== Step 1b: Fix chromosome names for ADMIXTURE ==="
# ADMIXTURE requires integer chromosome codes, not scaffold names
awk '{$1 = substr($1, 10); print}' merged_admixture_input.bim > merged_admixture_input_fix.bim
mv merged_admixture_input.bim merged_admixture_input_original.bim
mv merged_admixture_input_fix.bim merged_admixture_input.bim

echo "Checking first few lines of fixed .bim:"
head -5 merged_admixture_input.bim
echo "Sample count:"
wc -l merged_admixture_input.fam

echo "=== Step 2: ADMIXTURE K=2 to K=5 with cross-validation ==="

for K in 2 3 4 5; do
    echo "--- Running K=$K: $(date) ---"
    admixture --cv -j8 merged_admixture_input.bed $K \
        | tee admixture_K${K}.log
    echo "K=$K done: $(date)"
done

echo "=== Step 3: Summarize cross-validation errors ==="
echo ""
echo "CV errors (lower = better K):"
grep "CV error" admixture_K*.log

echo "=== All done: $(date) ==="
