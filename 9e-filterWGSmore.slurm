#!/bin/bash
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --mem=32G
#SBATCH --account=saarman-np
#SBATCH --partition=saarman-shared-np
#SBATCH --job-name=wgs_missingness_filter
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=u1055819@umail.utah.edu

module load bcftools
module load htslib

# ── paths ──────────────────────────────────────────────────────────────────
VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/vcf_filtered/merged_WGS_ddRAD_g70m70g50_ABfiltered_LDpruned_renamed.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/vcf_filtered

echo "=== Script 4: WGS-aware missingness filter ==="
echo "Start time: $(date)"
echo "Input SNPs:    $(bcftools view -H ${VCF} | wc -l)"
echo "Input samples: $(bcftools query -l ${VCF} | wc -l)"

# ── Step 1: Build WGS and ddRAD sample lists ───────────────────────────────
echo "--- Building sample lists ---"
bcftools query -l ${VCF} | grep -E '^(BE_|Cache_|OGD_|SGE_|SLC_)' \
    > ${OUT_DIR}/wgs_samples.txt
bcftools query -l ${VCF} | grep -vE '^(BE_|Cache_|OGD_|SGE_|SLC_)' \
    > ${OUT_DIR}/ddrad_samples.txt

echo "WGS samples:   $(wc -l < ${OUT_DIR}/wgs_samples.txt)"
echo "ddRAD samples: $(wc -l < ${OUT_DIR}/ddrad_samples.txt)"

# ── Step 2: Filter to sites with <50% missingness in WGS samples ───────────
echo "--- Filtering sites by missingness within WGS samples ---"
bcftools view -S ${OUT_DIR}/wgs_samples.txt ${VCF} | \
bcftools filter -i 'F_MISSING < 0.5' \
    --output-type z \
    --output ${OUT_DIR}/wgs_passing_sites.vcf.gz

bcftools index ${OUT_DIR}/wgs_passing_sites.vcf.gz

echo "Sites passing WGS missingness filter: $(bcftools view -H ${OUT_DIR}/wgs_passing_sites.vcf.gz | wc -l)"

# ── Step 3: Extract those passing sites from the full VCF (all 167 samples) 
echo "--- Extracting passing sites from full VCF ---"
bcftools query -f '%CHROM\t%POS\n' ${OUT_DIR}/wgs_passing_sites.vcf.gz \
    > ${OUT_DIR}/wgs_passing_sites.pos

bcftools view \
    -T ${OUT_DIR}/wgs_passing_sites.pos \
    ${VCF} \
    -O z -o ${OUT_DIR}/merged_WGS_ddRAD_g70m70g50_ABfiltered_LDpruned_renamed_WGSfilt.vcf.gz

bcftools index ${OUT_DIR}/merged_WGS_ddRAD_g70m70g50_ABfiltered_LDpruned_renamed_WGSfilt.vcf.gz

# ── Step 4: Cleanup temp files ─────────────────────────────────────────────
rm ${OUT_DIR}/wgs_passing_sites.vcf.gz
rm ${OUT_DIR}/wgs_passing_sites.vcf.gz.csi
rm ${OUT_DIR}/wgs_passing_sites.pos

chmod -R g+w /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/

echo ""
echo "=== Script 4 Summary ==="
echo "Input SNPs:    $(bcftools view -H ${VCF} | wc -l)"
echo "Input samples: $(bcftools query -l ${VCF} | wc -l)"
echo "Final SNPs:    $(bcftools view -H ${OUT_DIR}/merged_WGS_ddRAD_g70m70g50_ABfiltered_LDpruned_renamed_WGSfilt.vcf.gz | wc -l)"
echo "Final samples: $(bcftools query -l ${OUT_DIR}/merged_WGS_ddRAD_g70m70g50_ABfiltered_LDpruned_renamed_WGSfilt.vcf.gz | wc -l)"
echo "Output: merged_WGS_ddRAD_g70m70g50_ABfiltered_LDpruned_renamed_WGSfilt.vcf.gz"
echo "Done! End time: $(date)"
