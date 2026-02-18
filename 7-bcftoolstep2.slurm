



# 1. Depth filter
bcftools filter -i 'INFO/DP >= 130' \
    Culex_raw_variants.vcf.gz -O z -o Culex_filt1_depth.vcf.gz

# 2. Missingness filter  
vcftools --gzvcf Culex_filt1_depth.vcf.gz \
    --max-missing 0.8 --recode --stdout | bgzip > Culex_filt2_missing.vcf.gz

# 3. MAC filter
vcftools --gzvcf Culex_filt2_missing.vcf.gz \
    --mac 2 --recode --stdout | bgzip > Culex_filt3_mac.vcf.gz

# 4. Other filters as advised...
