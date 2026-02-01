#!/bin/bash

#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --array=1-$(wc -l < /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_bwa/bam_list.txt)
#SBATCH --job-name="samtools"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load samtools

# Directories
BAM_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_bwa
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_indexed
mkdir -p "$OUT_DIR"

# Get BAM for this array task
bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$BAM_DIR/bam_list.txt")

# Safety check
if [[ -z "$bam" ]]; then
    echo "No BAM found for task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

sample=$(basename "$bam" .bam)

echo "=== Processing $sample ==="

# Step 1: Name sort
samtools sort -n -@ "$SLURM_CPUS_PER_TASK" \
    -o "$OUT_DIR/${sample}.namesort.bam" \
    "$BAM_DIR/$bam"

# Step 2: Fix mate information
samtools fixmate -m \
    "$OUT_DIR/${sample}.namesort.bam" \
    "$OUT_DIR/${sample}.fixmate.bam"

# Step 3: Coordinate sort
samtools sort -@ "$SLURM_CPUS_PER_TASK" \
    -o "$OUT_DIR/${sample}.coordsort.bam" \
    "$OUT_DIR/${sample}.fixmate.bam"

# Step 4: Mark duplicates
samtools markdup -@ "$SLURM_CPUS_PER_TASK" \
    "$OUT_DIR/${sample}.coordsort.bam" \
    "$OUT_DIR/${sample}.markdup.bam"

# Step 5: Index
samtools index "$OUT_DIR/${sample}.markdup.bam"

# Step 6: QC
samtools flagstat \
    "$OUT_DIR/${sample}.markdup.bam" \
    > "$OUT_DIR/${sample}.flagstat.txt"

# Cleanup
rm "$OUT_DIR/${sample}.namesort.bam" \
   "$OUT_DIR/${sample}.fixmate.bam" \
   "$OUT_DIR/${sample}.coordsort.bam"

echo "=== Done $sample ==="
