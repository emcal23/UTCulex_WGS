#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=12:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --job-name="summary"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL


module load bcftools
module load samtools

# ── Paths ──────────────────────────────────────────────────────────────────
VCF_RAW=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_final_variants.vcf.gz
VCF_BIAS=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_stage2_bias_filtered.vcf.gz
VCF_THIN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_WGS_65samp_stage3_thinned.vcf.gz
FLAGSTAT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_final
COVERAGE_FILE=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_final/mergedcoverage_summary.txt
FLAGSTAT_FILE=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_final/mergedflagstat_summary_clean.txt

OUT=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/WGS_pipeline_summary.txt

echo "=============================================" > $OUT
echo "  WGS PIPELINE SUMMARY" >> $OUT
echo "  Generated: $(date)" >> $OUT
echo "=============================================" >> $OUT

# ── SNP counts at each stage ───────────────────────────────────────────────
echo "" >> $OUT
echo "--- SNP COUNTS BY STAGE ---" >> $OUT

echo -n "Stage 1 - After bcftools variant calling:      " >> $OUT
bcftools stats $VCF_RAW | grep "number of SNPs:" >> $OUT

echo -n "Stage 2 - After GATK bias filtering:           " >> $OUT
bcftools stats $VCF_BIAS | grep "number of SNPs:" >> $OUT

echo -n "Stage 3 - After vcftools missingness+thinning: " >> $OUT
bcftools stats $VCF_THIN | grep "number of SNPs:" >> $OUT

# ── Sample counts ──────────────────────────────────────────────────────────
echo "" >> $OUT
echo "--- SAMPLE COUNTS ---" >> $OUT
echo -n "Samples in raw VCF:    " >> $OUT
bcftools query -l $VCF_RAW | wc -l >> $OUT

echo -n "Samples in final VCF:  " >> $OUT
bcftools query -l $VCF_THIN | wc -l >> $OUT

# ── Genotyping rate per stage ──────────────────────────────────────────────
echo "" >> $OUT
echo "--- GENOTYPING RATES ---" >> $OUT

echo -n "Stage 1 missingness: " >> $OUT
bcftools stats $VCF_RAW | grep "^SN" | grep "missing" >> $OUT

echo -n "Stage 2 missingness: " >> $OUT
bcftools stats $VCF_BIAS | grep "^SN" | grep "missing" >> $OUT

echo -n "Stage 3 missingness: " >> $OUT
bcftools stats $VCF_THIN | grep "^SN" | grep "missing" >> $OUT

# ── Coverage summary ───────────────────────────────────────────────────────
echo "" >> $OUT
echo "--- COVERAGE SUMMARY (from mergedcoverage_summary.txt) ---" >> $OUT
if [ -f "$COVERAGE_FILE" ]; then
    cat $COVERAGE_FILE >> $OUT
    echo "" >> $OUT
    echo -n "Mean coverage across all samples: " >> $OUT
    awk 'NR>2 {sum+=$2; count++} END {printf "%.2fx\n", sum/count}' $COVERAGE_FILE >> $OUT
    echo -n "Min coverage: " >> $OUT
    awk 'NR>2 {print $2}' $COVERAGE_FILE | sort -n | head -1 >> $OUT
    echo -n "Max coverage: " >> $OUT
    awk 'NR>2 {print $2}' $COVERAGE_FILE | sort -n | tail -1 >> $OUT
else
    echo "WARNING: coverage file not found at $COVERAGE_FILE" >> $OUT
fi

# ── Flagstat summary ───────────────────────────────────────────────────────
echo "" >> $OUT
echo "--- ALIGNMENT SUMMARY (from mergedflagstat_summary_clean.txt) ---" >> $OUT
if [ -f "$FLAGSTAT_FILE" ]; then
    cat $FLAGSTAT_FILE >> $OUT
else
    echo "WARNING: flagstat summary not found at $FLAGSTAT_FILE" >> $OUT
fi

echo "" >> $OUT
echo "=============================================" >> $OUT
echo "  DONE" >> $OUT
echo "=============================================" >> $OUT

echo "Summary written to: $OUT"
