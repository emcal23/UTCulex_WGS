#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=8:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --job-name="prep_ddrad"

module load bcftools
module load htslib

DDRAD_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_populations_formerge/populations.snps.vcf.gz
#DDRAD_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_filtered/cx_ddRAD_combined2-3_g70m70g20_ABfiltered.p.snps.vcf


echo "Sorting VCF..."
bcftools sort $DDRAD_VCF -O z -o ${DDRAD_VCF%.vcf.gz}.sorted.vcf.gz

echo "Indexing sorted VCF..."
bcftools index ${DDRAD_VCF%.vcf.gz}.sorted.vcf.gz

echo "Done!"






# Compress
# bgzip -c $DDRAD_VCF > ${OUT_DIR}/cx_ddRAD_combined2-3_g70m70g20_ABfiltered.p.snps.vcf.gz
# Index
# tabix -p vcf ${OUT_DIR}/cx_ddRAD_combined2-3_g70m70g20_ABfiltered.p.snps.vcf.gz
#bgzip /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_populations_formerge/populations.snps.vcf
echo "Done!"
# echo "Output: ${OUT_DIR}/cx_ddRAD_combined2-3_g70m70g20_ABfiltered.p.snps.vcf.gz"
