#!/bin/bash

#SBATCH --partition=saarman-shared-np   
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00   # walltime limit (HH:MM:SS)
#SBATCH --mem=24576 # memory given in MB
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=16   # 20 processor core(s) per node X 2 threads per core
#SBATCH --job-name="troubleshooting"
#SBATCH --array=0-129%40
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=emily.calhoun@usu.edu

module load bcftools vcftools plink/1.9   # match your existing module lines
# module load plink2                       # for KING; skip KING if not available

IN=Culex_WGS_61samp_stage3_filtered_renamed.vcf.gz
OUT=Culex_WGS_61samp

# 1. Per-sample depth and missingness on the full VCF
vcftools --gzvcf $IN --depth --out ${OUT}_depth
vcftools --gzvcf $IN --missing-indv --out ${OUT}_missing

# 2. Complete-matrix SNP set: every sample has DP>=5, zero missing
bcftools filter -S . -e 'FMT/DP<5' $IN -Ou --threads 8 | \
  bcftools view -i 'F_MISSING=0' -Oz -o ${OUT}_DP5complete.vcf.gz --threads 8
bcftools index -t ${OUT}_DP5complete.vcf.gz
echo "SNPs in complete matrix:"
bcftools view -H ${OUT}_DP5complete.vcf.gz | wc -l

# 3. PCA, heterozygosity on the complete set
plink --vcf ${OUT}_DP5complete.vcf.gz --allow-extra-chr --double-id \
      --pca 10 --het --out ${OUT}_DP5complete

# 4. Kinship (KING) on the complete set
plink2 --vcf ${OUT}_DP5complete.vcf.gz --allow-extra-chr --double-id \
       --make-king-table --out ${OUT}_DP5complete_king
