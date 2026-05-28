#!/bin/bash
#SBATCH --time=4:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=4
#SBATCH --mem=32G
#SBATCH --account=saarman-np
#SBATCH --partition=saarman-shared-np
#SBATCH --job-name=plink_strict
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=emily.calhoun@usu.edu

module load plink

plink_dir=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_ddRAD_merged/plink_filtered
cd ${plink_dir}

in_file=merged_WGS_ddRAD

# ══════════════════════════════════════════════════════════════════════════
# FILTER SET 4 — ultra-strict: g70 → m70 → g10 (90% completeness required)
# ══════════════════════════════════════════════════════════════════════════
echo "=== Filter Set 4: g70m70g10 (90% complete) ==="
LOG=${in_file}_g70m70g10_plink_log.txt
cp /dev/null ${LOG}

# reuse g70m70 already computed in Script 1
plink --file ${in_file}_g70m70 --geno .1 --double-id --allow-extra-chr --recode --out ${in_file}_g70m70g10 >> ${LOG}

plink --file ${in_file}_g70m70g10 --allow-extra-chr --missing --out ${in_file}_g70m70g10_missing

echo "Set 4 (g70m70g10) SNPs:    $(wc -l < ${in_file}_g70m70g10.map)"
echo "Set 4 (g70m70g10) samples: $(wc -l < ${in_file}_g70m70g10.ped)"

# ══════════════════════════════════════════════════════════════════════════
# FILTER SET 5 — extreme: g70 → m70 → g05 (95% completeness required)
# ══════════════════════════════════════════════════════════════════════════
echo ""
echo "=== Filter Set 5: g70m70g05 (95% complete) ==="
LOG=${in_file}_g70m70g05_plink_log.txt
cp /dev/null ${LOG}

plink --file ${in_file}_g70m70 --geno .05 --double-id --allow-extra-chr --recode --out ${in_file}_g70m70g05 >> ${LOG}

plink --file ${in_file}_g70m70g05 --allow-extra-chr --missing --out ${in_file}_g70m70g05_missing

echo "Set 5 (g70m70g05) SNPs:    $(wc -l < ${in_file}_g70m70g05.map)"
echo "Set 5 (g70m70g05) samples: $(wc -l < ${in_file}_g70m70g05.ped)"

echo ""
echo "=== Summary ==="
echo "g70m70g10 SNPs:    $(wc -l < ${in_file}_g70m70g10.map)"
echo "g70m70g10 samples: $(wc -l < ${in_file}_g70m70g10.ped)"
echo "g70m70g05 SNPs:    $(wc -l < ${in_file}_g70m70g05.map)"
echo "g70m70g05 samples: $(wc -l < ${in_file}_g70m70g05.ped)"
echo "Done! $(date)"
