#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --mem=16G
#SBATCH --account=saarman-np
#SBATCH --partition=saarman-np
#SBATCH --job-name=reheader
#SBATCH --mail-type=BEGIN,END,FAIL


module load bcftools
module load htslib

VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/vcf_filtered/merged_WGS_ddRAD_g70m70g50_ABfiltered_LDpruned.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/vcf_filtered

# Build rename file: extract sample names, strip path/extension for WGS samples
bcftools query -l ${VCF} | awk '{
    # if name contains .bam, extract just the meaningful part before .markdup.bam
    if ($0 ~ /\.markdup\.bam/) {
        n = split($0, a, "/");       # split on /
        name = a[n];                 # take last element
        sub(/\.markdup\.bam.*/, "", name);  # strip .markdup.bam and everything after
        print $0 "\t" name
    } else {
        # ddRAD samples already clean - keep as-is
        print $0 "\t" $0
    }
}' > ${OUT_DIR}/sample_rename.txt

echo "Sample rename map:"
cat ${OUT_DIR}/sample_rename.txt

# Reheader VCF with clean sample names
bcftools reheader \
    -s ${OUT_DIR}/sample_rename.txt \
    ${VCF} \
    -o ${OUT_DIR}/merged_WGS_ddRAD_g70m70g50_ABfiltered_LDpruned_renamed.vcf.gz

bcftools index ${OUT_DIR}/merged_WGS_ddRAD_g70m70g50_ABfiltered_LDpruned_renamed.vcf.gz

echo "New sample names:"
bcftools query -l ${OUT_DIR}/merged_WGS_ddRAD_g70m70g50_ABfiltered_LDpruned_renamed.vcf.gz
