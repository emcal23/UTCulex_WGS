#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem=64G
#SBATCH --account=saarman-np
#SBATCH --partition=saarman-np
#SBATCH --job-name=plink_filter
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=emily.calhoun@usu.edu

module load plink

# ── paths ──────────────────────────────────────────────────────────────────
in_path=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged
in_file=merged_WGS_ddRAD
out_dir=${in_path}/plink_filtered
mkdir -p ${out_dir}
cd ${out_dir}

echo "=== Script 1: PLINK Missingness Filtering ==="
echo "Start time: $(date)"

# ── Step 0: VCF → PLINK ────────────────────────────────────────────────────
echo "--- Converting VCF to PLINK ---"
plink --vcf ${in_path}/${in_file}.vcf.gz \
      --double-id --allow-extra-chr \
      --make-bed --out ${in_file}

plink --bfile ${in_file} \
      --double-id --allow-extra-chr \
      --recode tab --out ${in_file}

echo "Input SNPs:    $(wc -l < ${in_file}.map)"
echo "Input samples: $(wc -l < ${in_file}.ped)"


# ══════════════════════════════════════════════════════════════════════════
# FILTER SET 1 — MEDIUM: g70 → m70 → g60 → m60 → g50 → m50
# ══════════════════════════════════════════════════════════════════════════
echo ""
echo "--- Filter Set 1: g70m70g60m60g50m50 ---"
LOG1=${in_file}_g70m70g60m60g50m50_plink_log.txt
cp /dev/null ${LOG1}

plink --file ${in_file}                    --geno .7 --double-id --allow-extra-chr --recode --out ${in_file}_g70                >> ${LOG1}
plink --file ${in_file}_g70                --mind .7 --double-id --allow-extra-chr --recode --out ${in_file}_g70m70             >> ${LOG1}
plink --file ${in_file}_g70m70             --geno .6 --double-id --allow-extra-chr --recode --out ${in_file}_g70m70g60          >> ${LOG1}
plink --file ${in_file}_g70m70g60          --mind .6 --double-id --allow-extra-chr --recode --out ${in_file}_g70m70g60m60       >> ${LOG1}
plink --file ${in_file}_g70m70g60m60       --geno .5 --double-id --allow-extra-chr --recode --out ${in_file}_g70m70g60m60g50    >> ${LOG1}
plink --file ${in_file}_g70m70g60m60g50    --mind .5 --double-id --allow-extra-chr --recode --out ${in_file}_g70m70g60m60g50m50 >> ${LOG1}

plink --file ${in_file}_g70m70g60m60g50m50 --allow-extra-chr --missing --out ${in_file}_g70m70g60m60g50m50_missing

echo "Set 1 SNPs:    $(wc -l < ${in_file}_g70m70g60m60g50m50.map)"
echo "Set 1 samples: $(wc -l < ${in_file}_g70m70g60m60g50m50.ped)"


# ══════════════════════════════════════════════════════════════════════════
# FILTER SET 2 — MEDIUM geno + SOFT mind: g70 → m70 → g50
# ══════════════════════════════════════════════════════════════════════════
echo ""
echo "--- Filter Set 2: g70m70g50 ---"
LOG2=${in_file}_g70m70g50_plink_log.txt
cp /dev/null ${LOG2}

# reuse g70 and g70m70 intermediates already generated above
plink --file ${in_file}_g70m70 --geno .5 --double-id --allow-extra-chr --recode --out ${in_file}_g70m70g50 >> ${LOG2}

plink --file ${in_file}_g70m70g50 --allow-extra-chr --missing --out ${in_file}_g70m70g50_missing

echo "Set 2 SNPs:    $(wc -l < ${in_file}_g70m70g50.map)"
echo "Set 2 samples: $(wc -l < ${in_file}_g70m70g50.ped)"


# ══════════════════════════════════════════════════════════════════════════
# FILTER SET 3 — HARD geno + SOFT mind: g70 → m70 → g20
# ══════════════════════════════════════════════════════════════════════════
echo ""
echo "--- Filter Set 3: g70m70g20 ---"
LOG3=${in_file}_g70m70g20_plink_log.txt
cp /dev/null ${LOG3}

# reuse g70m70 intermediate already generated above
plink --file ${in_file}_g70m70 --geno .2 --double-id --allow-extra-chr --recode --out ${in_file}_g70m70g20 >> ${LOG3}

plink --file ${in_file}_g70m70g20 --allow-extra-chr --missing --out ${in_file}_g70m70g20_missing

echo "Set 3 SNPs:    $(wc -l < ${in_file}_g70m70g20.map)"
echo "Set 3 samples: $(wc -l < ${in_file}_g70m70g20.ped)"


# ══════════════════════════════════════════════════════════════════════════
# SUMMARY — inspect these counts to decide which filter set to use in Script 2
# ══════════════════════════════════════════════════════════════════════════
echo ""
echo "=== FILTERING SUMMARY ==="
echo "Input SNPs:                         $(wc -l < ${in_file}.map)"
echo "Input samples:                      $(wc -l < ${in_file}.ped)"
echo ""
echo "Set 1 (g70m70g60m60g50m50) SNPs:    $(wc -l < ${in_file}_g70m70g60m60g50m50.map)"
echo "Set 1 (g70m70g60m60g50m50) samples: $(wc -l < ${in_file}_g70m70g60m60g50m50.ped)"
echo ""
echo "Set 2 (g70m70g50) SNPs:             $(wc -l < ${in_file}_g70m70g50.map)"
echo "Set 2 (g70m70g50) samples:          $(wc -l < ${in_file}_g70m70g50.ped)"
echo ""
echo "Set 3 (g70m70g20) SNPs:             $(wc -l < ${in_file}_g70m70g20.map)"
echo "Set 3 (g70m70g20) samples:          $(wc -l < ${in_file}_g70m70g20.ped)"
echo ""
echo "Done! End time: $(date)"
echo ">>> Now inspect .imiss/.lmiss files and choose a filter set, then run Script 2."
