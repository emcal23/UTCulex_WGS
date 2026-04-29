#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=1:00:00
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="filter_missingness"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools

# Define input and output paths
INPUT_VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/merged_WGS_ddRAD_raw.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged
FILTERED_VCF=${OUT_DIR}/merged_WGS_ddRAD_filtered.vcf.gz

echo "=== Filtering VCF for Missingness ==="
echo "Start time: $(date)"
echo "Input VCF: $INPUT_VCF"
echo "Output VCF: $FILTERED_VCF"

# Check if input file exists
if [ ! -f "$INPUT_VCF" ]; then
    echo "Error: Input VCF file not found: $INPUT_VCF"
    exit 1
fi

# Get initial stats
echo "=== Initial VCF Stats ==="
echo "Initial samples: $(bcftools query -l $INPUT_VCF | wc -l)"
echo "Initial variants: $(bcftools view -H $INPUT_VCF | wc -l)"

# Step 1: Filter samples with >30% missing data
echo "=== Step 1: Filtering samples with >30% missing data ==="

# Create list of samples to keep (<=30% missing)
echo "Identifying samples to keep..."
bcftools query -l "$INPUT_VCF" > "${OUT_DIR}/all_samples.txt"

# Create header for sample filtering
echo -e "SAMPLE\tF_MISSING\tKEEP" > "${OUT_DIR}/sample_filter_results.txt"

# Check each sample's missing data rate
while read sample; do
    # Count missing genotypes for this sample
    total_sites=$(bcftools view -H "$INPUT_VCF" | wc -l)
    missing_count=$(bcftools view -s "$sample" "$INPUT_VCF" | bcftools query -f '[%GT]\n' | awk '
        BEGIN { missing = 0 }
        /\.\/\./ { missing++ }
        /\|\|/ { missing++ }
        END { print missing }
    ')
    
    # Calculate missing frequency
    missing_freq=$(awk -v missing="$missing_count" -v total="$total_sites" 'BEGIN { printf "%.4f", missing/total }')
    
    # Decide if we keep this sample (missing <= 0.30)
    keep=$(awk -v freq="$missing_freq" 'BEGIN { print (freq <= 0.30) ? "KEEP" : "REMOVE" }')
    
    echo -e "$sample\t$missing_freq\t$keep" >> "${OUT_DIR}/sample_filter_results.txt"
    
    if [ "$keep" = "KEEP" ]; then
        echo "$sample" >> "${OUT_DIR}/samples_to_keep.txt"
    fi
    
    echo "Sample: $sample, Missing: $missing_freq, Decision: $keep"
done < "${OUT_DIR}/all_samples.txt"

# Count samples being kept
samples_kept=$(wc -l < "${OUT_DIR}/samples_to_keep.txt")
samples_total=$(wc -l < "${OUT_DIR}/all_samples.txt")
samples_removed=$((samples_total - samples_kept))

echo "Samples to keep: $samples_kept (removed: $samples_removed)"

# Apply sample filtering
echo "Applying sample filter..."
bcftools view -S "${OUT_DIR}/samples_to_keep.txt" "$INPUT_VCF" -O z -o "${OUT_DIR}/temp_sample_filtered.vcf.gz"
bcftools index "${OUT_DIR}/temp_sample_filtered.vcf.gz"

# Step 2: Filter SNPs with >20% missing data
echo "=== Step 2: Filtering SNPs with >20% missing data ==="

# Filter variants with <=20% missing data (>=80% call rate)
bcftools view -i 'F_MISSING<=0.20' "${OUT_DIR}/temp_sample_filtered.vcf.gz" -O z -o "$FILTERED_VCF"
bcftools index "$FILTERED_VCF"

# Get final stats
echo "=== Final VCF Stats ==="
final_samples=$(bcftools query -l "$FILTERED_VCF" | wc -l)
final_variants=$(bcftools view -H "$FILTERED_VCF" | wc -l)
echo "Final samples: $final_samples"
echo "Final variants: $final_variants"

# Create summary report
echo "=== Filtering Summary ===" > "${OUT_DIR}/filtering_summary.txt"
echo "Initial samples: $(bcftools query -l $INPUT_VCF | wc -l)" >> "${OUT_DIR}/filtering_summary.txt"
echo "Initial variants: $(bcftools view -H $INPUT_VCF | wc -l)" >> "${OUT_DIR}/filtering_summary.txt"
echo "" >> "${OUT_DIR}/filtering_summary.txt"
echo "Samples removed (>30% missing): $samples_removed" >> "${OUT_DIR}/filtering_summary.txt"
echo "Samples kept: $samples_kept" >> "${OUT_DIR}/filtering_summary.txt"
echo "" >> "${OUT_DIR}/filtering_summary.txt"
echo "Final samples: $final_samples" >> "${OUT_DIR}/filtering_summary.txt"
echo "Final variants: $final_variants" >> "${OUT_DIR}/filtering_summary.txt"
echo "" >> "${OUT_DIR}/filtering_summary.txt"
echo "Filtering criteria:" >> "${OUT_DIR}/filtering_summary.txt"
echo "- Samples: ≤30% missing data" >> "${OUT_DIR}/filtering_summary.txt"
echo "- SNPs: ≤20% missing data" >> "${OUT_DIR}/filtering_summary.txt"

# Clean up temporary files
rm "${OUT_DIR}/temp_sample_filtered.vcf.gz"
rm "${OUT_DIR}/temp_sample_filtered.vcf.gz.csi"

echo ""
echo "=== Output Files Created ==="
echo "Filtered VCF: $FILTERED_VCF"
echo "Sample filter results: ${OUT_DIR}/sample_filter_results.txt"
echo "Samples kept: ${OUT_DIR}/samples_to_keep.txt"
echo "Filtering summary: ${OUT_DIR}/filtering_summary.txt"

echo ""
echo "End time: $(date)"
echo "=== Complete ==="
