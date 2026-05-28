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


module load plink
module load bcftools
module load htslib

IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/vcf_filtered/merged_WGS_ddRAD_g70m70g10_ABfiltered.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/vcf_filtered
OUT_STEM=${OUT_DIR}/merged_WGS_ddRAD_g70m70g10_ABfiltered_LDpruned

echo "=== LD Pruning (r2-based) ==="
echo "Start time: $(date)"
echo "Input SNPs: $(bcftools view -H $IN | wc -l)"

# Step 1: Calculate LD and identify SNPs to prune
# 50-SNP window, sliding by 10, r2 threshold 0.5
plink --vcf ${IN} \
      --double-id --allow-extra-chr \
      --indep-pairwise 50 10 0.5 \
      --out ${OUT_STEM}

echo "SNPs to keep: $(wc -l < ${OUT_STEM}.prune.in)"
echo "SNPs to remove: $(wc -l < ${OUT_STEM}.prune.out)"

# Step 2: Extract pruned SNP set and recode to VCF
plink --vcf ${IN} \
      --double-id --allow-extra-chr \
      --extract ${OUT_STEM}.prune.in \
      --recode vcf \
      --out ${OUT_STEM}

# Step 3: bgzip and index
bgzip ${OUT_STEM}.vcf
bcftools index ${OUT_STEM}.vcf.gz

echo ""
echo "=== LD Pruning Summary ==="
echo "Input SNPs:          $(bcftools view -H $IN | wc -l)"
echo "SNPs after pruning:  $(bcftools view -H ${OUT_STEM}.vcf.gz | wc -l)"
echo "Samples retained:    $(bcftools query -l ${OUT_STEM}.vcf.gz | wc -l)"
echo "Output: ${OUT_STEM}.vcf.gz"
echo "Done! End time: $(date)"
