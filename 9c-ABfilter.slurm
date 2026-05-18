#!/bin/bash
#SBATCH --time=4:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --mem=32G
#SBATCH --account=saarman-np
#SBATCH --partition=saarman-np
#SBATCH --job-name=ab_filter
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=emily.calhoun@usu.edu

module load bcftools
module load htslib

# ── USER CHOICE ────────────────────────────────────────────────────────────
filter_include="g70m70g50"
plate_name="merged_WGS_ddRAD"

# ── paths ──────────────────────────────────────────────────────────────────
in_dir=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/vcf_filtered
in_file=${in_dir}/${plate_name}_${filter_include}_filtered.recode.vcf.gz
out_dir=${in_dir}
out_file=${out_dir}/${plate_name}_${filter_include}_ABfiltered.vcf.gz

# temp files
snp_data=${out_dir}/snp_data_${filter_include}.txt
filtered_snps=${out_dir}/filtered_snps_${filter_include}.tsv
snps_to_keep=${out_dir}/snps_to_keep_${filter_include}.txt

echo "=== Script 3: AB Filter ==="
echo "Input: ${in_file}"
echo "Start time: $(date)"
echo "Input SNPs: $(bcftools view -H ${in_file} | wc -l)"

# ── Step 1: Biallelic SNPs only + QUAL and depth pre-filter ───────────────
# NOTE: keeping biallelic SNPs only; indels excluded for population genomics
echo "Step 1: Pre-filtering biallelic SNPs by QUAL and depth..."
bcftools view -m2 -M2 -v snps ${in_file} | \
bcftools filter -i 'QUAL >= 30 && INFO/DP >= 10 && INFO/DP <= 500' \
    -O z -o ${out_dir}/${plate_name}_${filter_include}_biallelic_prefiltered.vcf.gz

bcftools index ${out_dir}/${plate_name}_${filter_include}_biallelic_prefiltered.vcf.gz
echo "After biallelic + QUAL/DP filter: $(bcftools view -H ${out_dir}/${plate_name}_${filter_include}_biallelic_prefiltered.vcf.gz | wc -l) SNPs"

# ── Step 2: Extract GT and AD fields for AB calculation ───────────────────
# FORMAT is per-sample, so query extracts each sample's GT and AD
echo "Step 2: Extracting GT and AD fields..."
bcftools query \
    -f '%CHROM\t%POS\t%ID[\t%GT\t%AD]\n' \
    ${out_dir}/${plate_name}_${filter_include}_biallelic_prefiltered.vcf.gz \
    > ${snp_data}

echo "SNPs to evaluate for AB: $(wc -l < ${snp_data})"

# ── Step 3: Calculate per-SNP average AB across heterozygotes ─────────────
# Filters SNPs where average het AB is 0.3–0.7 (O'Leary et al. 2018)
echo "Step 3: Calculating average allele balance per SNP..."
awk '
BEGIN { OFS="\t" }
{
    chrom=$1; pos=$2; id=$3;
    sum_ab = 0; count_het = 0;
    for (i=4; i<=NF; i+=2) {
        gt = $i; ad = $(i+1);
        # only evaluate heterozygous genotypes
        if (gt == "0/1" || gt == "1/0" || gt == "0|1" || gt == "1|0") {
            n = split(ad, depths, ",");
            if (n >= 2 && (depths[1] + depths[2]) > 0) {
                ab = depths[2] / (depths[1] + depths[2]);
                sum_ab += ab;
                count_het++;
            }
        }
    }
    # only filter SNPs that have at least one heterozygote
    if (count_het > 0) {
        avg_ab = sum_ab / count_het;
        if (avg_ab >= 0.3 && avg_ab <= 0.7) {
            print chrom, pos, id, avg_ab;
        }
    } else {
        # no hets: keep the SNP (cannot evaluate AB)
        print chrom, pos, id, "NA";
    }
}' ${snp_data} > ${filtered_snps}

echo "SNPs passing AB filter: $(wc -l < ${filtered_snps})"

# ── Step 4: Make site keep-list and subset VCF ────────────────────────────
echo "Step 4: Subsetting VCF to AB-passing sites..."
cut -f1,2 ${filtered_snps} > ${snps_to_keep}

bcftools view -T ${snps_to_keep} \
    ${out_dir}/${plate_name}_${filter_include}_biallelic_prefiltered.vcf.gz \
    -O z -o ${out_file}

bcftools index ${out_file}

# ── Step 5: Cleanup temp files ────────────────────────────────────────────
rm ${snp_data} ${filtered_snps} ${snps_to_keep}
rm ${out_dir}/${plate_name}_${filter_include}_biallelic_prefiltered.vcf.gz
rm ${out_dir}/${plate_name}_${filter_include}_biallelic_prefiltered.vcf.gz.csi

chmod -R g+w /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/

echo ""
echo "=== Script 3 Summary ==="
echo "Input SNPs (post-missingness filter): $(bcftools view -H ${in_file} | wc -l)"
echo "Final SNPs (post-AB filter):          $(bcftools view -H ${out_file} | wc -l)"
echo "Final samples:                        $(bcftools query -l ${out_file} | wc -l)"
echo "Output: ${out_file}"
echo "Done! End time: $(date)"
