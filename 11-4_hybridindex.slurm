#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=6:00:00
#SBATCH --mem=32G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="hybridindex"
#SBATCH -o hybridindex_%j.out
#SBATCH -e hybridindex_%j.err

module load plink/1.90

IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_admixture/52samp/Culex_WGS_52samp_all
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_hybridindex
mkdir -p $OUT_DIR
cd $OUT_DIR

# 1. Reference groups
grep -E "^SGE_" ${IN}.fam | awk '{print $1, $2}' > ref_SGE.txt
grep -E "^(Cache|BE|OGD)_" ${IN}.fam | awk '{print $1, $2}' > ref_north.txt
echo "SGE reference n:"; wc -l < ref_SGE.txt
echo "North reference n:"; wc -l < ref_north.txt

# 2. Allele frequencies in each reference (A1 kept fixed from .bim)
plink --bfile $IN --allow-extra-chr --keep-allele-order --keep ref_SGE.txt   --freq --out freq_SGE
plink --bfile $IN --allow-extra-chr --keep-allele-order --keep ref_north.txt --freq --out freq_north

# 3. AIMs: frequency difference >= 0.8, >=6/8 SGE alleles and >=20/26 north alleles genotyped
#    Output: SNP ID + which allele (A1 or A2) is the quinx allele
awk 'NR==FNR { if (FNR>1 && $6>=6) { s[$2]=$5 }; next }
     FNR>1 && ($2 in s) && $6>=20 {
       d = s[$2] - $5; if (d < 0) d = -d;
       if (d >= 0.8) print $2, (s[$2] > $5 ? "A1" : "A2")
     }' freq_SGE.frq freq_north.frq > aims_d0.8_all.txt
echo "AIMs (delta >= 0.8) before thinning:"; wc -l < aims_d0.8_all.txt

# How many at stricter cutoffs, for reference
awk 'NR==FNR { if (FNR>1 && $6>=6) { s[$2]=$5 }; next }
     FNR>1 && ($2 in s) && $6>=20 { d = s[$2] - $5; if (d<0) d=-d;
       if (d>=0.9) n9++; if (d>=0.999) n10++ }
     END { print "delta>=0.9:", n9, "  fixed (delta=1):", n10 }' freq_SGE.frq freq_north.frq

# 4. Thin to 1 AIM per 10 kb
cut -d' ' -f1 aims_d0.8_all.txt > aims_ids.txt
plink --bfile $IN --allow-extra-chr --extract aims_ids.txt --bp-space 10000 \
      --write-snplist --out aims_thinned
echo "AIMs after 10 kb thinning:"; wc -l < aims_thinned.snplist

# 5. Genotypes at AIMs for all 52 samples (counts of A1 allele: 0/1/2)
plink --bfile $IN --allow-extra-chr --keep-allele-order --extract aims_thinned.snplist \
      --recode A --out aims_genotypes
echo "Done: $(date)"
