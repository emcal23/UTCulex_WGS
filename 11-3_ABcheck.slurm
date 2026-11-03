#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=6:00:00
#SBATCH --mem=8G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --job-name="ABcheck"
#SBATCH -o ABcheck_%j.out
#SBATCH -e ABcheck_%j.err

cd /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf
module load bcftools

VCF=Culex_WGS_53samp_stage3_filtered.vcf.gz
bcftools query -l $VCF | grep -E "^(SLC|SGE)" > ABcheck_samples.txt
echo "Samples:"
cat ABcheck_samples.txt

# For each het genotype with >=10 reads, bin alt-allele fraction into 0.05 bins
bcftools view -S ABcheck_samples.txt $VCF -Ou | \
  bcftools query -f '[%SAMPLE\t%GT\t%AD\n]' | \
  awk -F'\t' '($2=="0/1" || $2=="0|1") {
      split($3, a, ","); r=a[1]; x=a[2]; d=r+x;
      if (d>=10) { b=int((x/d)*20)/20; c[$1"\t"b]++ }
    }
    END { for (k in c) print k"\t"c[k] }' > ABcheck_hist.txt

echo "Done:"
wc -l ABcheck_hist.txt
