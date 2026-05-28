#!/bin/bash
#SBATCH --time=4:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --mem=32G
#SBATCH --account=saarman-np
#SBATCH --partition=saarman-np
#SBATCH --job-name=plink_to_vcf
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=emily.calhoun@usu.edu

module load plink
module load vcftools
module load htslib
module load bcftools 

# ── USER CHOICE: set these after reviewing Script 1 summary ───────────────
filter_include="g70m70g10"      # NOTE: choose from g70m70g60m60g50m50, g70m70g50, g70m70g20
plate_name="merged_WGS_ddRAD"        # root name for output files

# ── paths ──────────────────────────────────────────────────────────────────
in_vcf=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/merged_WGS_ddRAD.vcf.gz
plink_dir=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/plink_filtered
out_dir=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/vcf_filtered
plink_stem=${plink_dir}/merged_WGS_ddRAD_${filter_include}

mkdir -p ${out_dir}
cd ${out_dir}

echo "=== Script 2: PLINK output → filtered VCF ==="
echo "Filter set: ${filter_include}"
echo "Start time: $(date)"

# ── Extract site list from PLINK .map (chrom + position) ──────────────────
# PLINK .map columns: chrom, SNP_ID, cM, bp_position
echo "Extracting site positions from PLINK .map..."
awk '{print $1 "\t" $4}' ${plink_stem}.map > ${out_dir}/${plate_name}_${filter_include}.pos
echo "Sites to extract: $(wc -l < ${out_dir}/${plate_name}_${filter_include}.pos)"

# ── Extract sample list from PLINK .nosex ─────────────────────────────────
# .nosex has FID IID; vcftools --keep needs one column (IID with --double-id means FID=IID)
echo "Extracting sample list from PLINK .nosex..."
awk '{print $2}' ${plink_stem}.nosex > ${out_dir}/${plate_name}_${filter_include}.samples
echo "Samples to keep: $(wc -l < ${out_dir}/${plate_name}_${filter_include}.samples)"

# ── Subset original VCF to passing sites and samples ──────────────────────
echo "Subsetting VCF..."
vcftools --gzvcf ${in_vcf} \
    --positions ${out_dir}/${plate_name}_${filter_include}.pos \
    --keep ${out_dir}/${plate_name}_${filter_include}.samples \
    --recode --recode-INFO-all \
    --out ${out_dir}/${plate_name}_${filter_include}_filtered

# bgzip and index for bcftools in Script 3
bgzip ${out_dir}/${plate_name}_${filter_include}_filtered.recode.vcf
bcftools index ${out_dir}/${plate_name}_${filter_include}_filtered.recode.vcf.gz

echo ""
echo "=== Script 2 Summary ==="
echo "Filter set used:  ${filter_include}"
echo "Output VCF:       ${plate_name}_${filter_include}_filtered.recode.vcf.gz"
echo "Final SNPs:       $(bcftools view -H ${out_dir}/${plate_name}_${filter_include}_filtered.recode.vcf.gz | wc -l)"
echo "Final samples:    $(bcftools query -l ${out_dir}/${plate_name}_${filter_include}_filtered.recode.vcf.gz | wc -l)"
echo "Done! End time: $(date)"
echo ">>> Now run Script 3 for AB filtering."
