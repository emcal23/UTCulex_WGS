#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=12:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --job-name="merge_lanes"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load samtools

# Directories
BAM_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_bwa
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_mergedbams

mkdir -p "$OUT_DIR"

echo "=== Step 1: Identifying unique samples ==="
# Extract unique sample IDs (everything before _S)
cd "$BAM_DIR"
for bam in *.bam; do
    # Extract sample ID: everything before the S number
    sample=$(echo "$bam" | sed 's/_S[0-9]*_L[0-9]*.bam//')
    echo "$sample"
done | sort -u > "$OUT_DIR/unique_samples.txt"

echo "Found $(cat $OUT_DIR/unique_samples.txt | wc -l) unique biological samples"

echo "=== Step 2: Merging lanes for each sample ==="
# Merge BAMs for each unique sample
while read sample; do
    echo "--- Processing $sample ---"
    
    # Find all BAMs for this sample
    bams=$(ls ${sample}_S*_L*.bam 2>/dev/null | tr '\n' ' ')
    
    if [ -z "$bams" ]; then
        echo "WARNING: No BAMs found for $sample"
        continue
    fi
    
    # Count how many BAMs
    num_bams=$(echo "$bams" | wc -w)
    
    if [ "$num_bams" -eq 1 ]; then
        # Only one lane, just copy it
        echo "  Single lane - copying"
        cp $bams "$OUT_DIR/${sample}.bam"
    else
        # Multiple lanes, merge them
        echo "  Merging $num_bams lanes"
        samtools merge -@ "$SLURM_CPUS_PER_TASK" \
            "$OUT_DIR/${sample}.bam" \
            $bams
    fi
    
done < "$OUT_DIR/unique_samples.txt"

echo "=== Step 3: Creating BAM list for next step ==="
# Create mergedbam_list.txt for the duplicate marking step
ls "$OUT_DIR"/*.bam | xargs -n 1 basename > "$OUT_DIR/mergedbam_list.txt"

echo ""
echo "=========================================="
echo "MERGING COMPLETE!"
echo "=========================================="
echo "Original BAMs (with lanes): $(ls $BAM_DIR/*.bam | wc -l)"
echo "Merged BAMs (biological samples): $(cat $OUT_DIR/bam_list.txt | wc -l)"
echo ""
echo "Next step: Update script 4 to use these merged BAMs"
echo "Update --array=1-$(cat $OUT_DIR/bam_list.txt | wc -l) in script 4"
echo "=========================================="
