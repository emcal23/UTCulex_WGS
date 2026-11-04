#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=12:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --job-name="FST52"
#SBATCH -o FST52_%j.out
#SBATCH -e FST52_%j.err

module load bcftools
module load vcftools

VCF=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_WGS_53samp_stage3_filtered.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_FST/52samp
mkdir -p $OUT_DIR
cd $OUT_DIR

# 1. One sample list per site (SGE_017 left out)
SITES="Cache BE OGD SLC UTCO WMAD SGE"
for S in $SITES; do
  bcftools query -l $VCF | grep "^${S}_" | grep -v "SGE_017" > pop_${S}.txt
  echo "$S: $(wc -l < pop_${S}.txt) samples"
done

# 2. Pairwise Weir & Cockerham FST
echo -e "pop1\tpop2\tweighted_FST\tmean_FST" > pairwise_FST_summary.txt
set -- $SITES
for A in $SITES; do
  for B in $SITES; do
    if [[ "$A" < "$B" ]]; then
      echo "--- $A vs $B: $(date) ---"
      vcftools --gzvcf $VCF --weir-fst-pop pop_${A}.txt --weir-fst-pop pop_${B}.txt \
               --out FST_${A}_${B} 2> /dev/null
      W=$(grep "weighted Fst estimate" FST_${A}_${B}.log | awk '{print $NF}')
      M=$(grep "mean Fst estimate" FST_${A}_${B}.log | awk '{print $NF}')
      echo -e "${A}\t${B}\t${W}\t${M}" >> pairwise_FST_summary.txt
      rm -f FST_${A}_${B}.weir.fst
    fi
  done
done

echo "=== Summary ==="
cat pairwise_FST_summary.txt
echo "Done: $(date)"
