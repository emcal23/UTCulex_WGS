#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=01:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=1
#SBATCH --array=0-20
#SBATCH --job-name="FST52arr"
#SBATCH -o FST52arr_%A_%a.out
#SBATCH -e FST52arr_%A_%a.err

module load vcftools

VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_WGS_53samp_stage3_filtered.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_FST/52samp
cd $OUT_DIR

# Build the 21 pairs; pop_*.txt files already exist from the first run
SITES=(BE Cache OGD SGE SLC UTCO WMAD)
PAIRS=()
for ((i=0; i<${#SITES[@]}; i++)); do
  for ((j=i+1; j<${#SITES[@]}; j++)); do
    PAIRS+=("${SITES[i]} ${SITES[j]}")
  done
done
read A B <<< "${PAIRS[$SLURM_ARRAY_TASK_ID]}"

echo "Pair $SLURM_ARRAY_TASK_ID: $A vs $B  $(date)"
vcftools --gzvcf $VCF --weir-fst-pop pop_${A}.txt --weir-fst-pop pop_${B}.txt \
         --out FST_${A}_${B}
echo "exit code: $?  $(date)"
gzip -f FST_${A}_${B}.weir.fst
