#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=48:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --job-name="admix52"
#SBATCH -o admix52_%j.out
#SBATCH -e admix52_%j.err
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load plink/1.90
module load admixture/1.3.0

VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_WGS_53samp_stage3_filtered.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_admixture/52samp
PFX=Culex_WGS_52samp
mkdir -p $OUT_DIR
cd $OUT_DIR

echo "=== Step 1: VCF to PLINK, drop SGE_017 (relative of SGE_016): $(date) ==="
echo "SGE_017_153_040 SGE_017_153_040" > remove_relative.txt
plink --vcf $VCF --make-bed --allow-extra-chr --double-id \
      --set-missing-var-ids @:# \
      --remove remove_relative.txt \
      --out ${PFX}_all

echo "=== Step 2: LD prune (r2 < 0.1): $(date) ==="
plink --bfile ${PFX}_all --allow-extra-chr --indep-pairwise 50 10 0.1 --out ${PFX}_prune
plink --bfile ${PFX}_all --allow-extra-chr --extract ${PFX}_prune.prune.in \
      --make-bed --out ${PFX}_LDpruned

echo "=== Step 3: Set chromosome names to 0 for ADMIXTURE ==="
awk '{$1="0"; print}' ${PFX}_LDpruned.bim > tmp.bim && mv tmp.bim ${PFX}_LDpruned.bim
echo "First lines of .bim:"
head -3 ${PFX}_LDpruned.bim
echo "SNPs after LD pruning:"
wc -l ${PFX}_LDpruned.bim
echo "Sample count (should be 52):"
wc -l ${PFX}_LDpruned.fam

echo "=== Step 4: ADMIXTURE K=1-6, 5 replicates each: $(date) ==="
for K in 1 2 3 4 5 6; do
  for rep in 1 2 3 4 5; do
    echo "--- K=$K rep=$rep: $(date) ---"
    admixture --cv -j16 -s $((K*100+rep)) ${PFX}_LDpruned.bed $K > log_K${K}_rep${rep}.out
    mv ${PFX}_LDpruned.${K}.Q ${PFX}_K${K}_rep${rep}.Q
    mv ${PFX}_LDpruned.${K}.P ${PFX}_K${K}_rep${rep}.P
  done
done

echo "=== Step 5: Summaries: $(date) ==="
grep -H "CV error" log_K*_rep*.out > CV_errors.txt
grep -H "^Loglikelihood" log_K*_rep*.out > loglikelihoods.txt
cat CV_errors.txt
echo "=== All done: $(date) ==="
