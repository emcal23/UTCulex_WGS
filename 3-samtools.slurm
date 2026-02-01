#!/bin/bash

# job standard output will go to the file slurm-%j.out (where %j is the job ID)

#SBATCH --partition=saarman-np   
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00   # walltime limit (HH:MM:SS)
#SBATCH --mem=32G
#SBATCH --nodes=1   # number of nodes
#SBATCH --ntasks-per-node=16   # 20 processor core(s) per node X 2 threads per core
#SBATCH --job-name="samtools"
#SBATCH --mail-user=emily.calhoun@usu.edu    # email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

# Load samtools to remove PCR duplicates

module load samtools

# Directories
BAM_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_bwa
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_indexed
mkdir -p $OUT_DIR

# Get BAM for this array task
bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $BAM_DIR/bam_list.txt)
sample=$(basename $bam .bam)

echo "=== Processing $sample ==="

# Step 1: Name sort
samtools sort -n -@ $SLURM_CPUS_PER_TASK -o $OUT_DIR/${sample}.namesort.bam $bam

# Step 2: Fix mate information (required before markdup)
samtools fixmate -m $OUT_DIR/${sample}.namesort.bam $OUT_DIR/${sample}.fixmate.bam

# Step 3: Coordinate sort
samtools sort -@ $SLURM_CPUS_PER_TASK -o $OUT_DIR/${sample}.coordsort.bam $OUT_DIR/${sample}.fixmate.bam

# Step 4: Mark duplicates
samtools markdup -@ $SLURM_CPUS_PER_TASK $OUT_DIR/${sample}.coordsort.bam $OUT_DIR/${sample}.markdup.bam

# Step 5: Index the final BAM
samtools index $OUT_DIR/${sample}.markdup.bam

# Step 6: Optional QC
samtools flagstat $OUT_DIR/${sample}.markdup.bam > $OUT_DIR/${sample}.flagstat.txt

# Cleanup intermediate BAMs to save space
rm $OUT_DIR/${sample}.namesort.bam $OUT_DIR/${sample}.fixmate.bam $OUT_DIR/${sample}.coordsort.bam

echo "=== Done $sample ==="
