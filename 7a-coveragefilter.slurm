#!/bin/bash
#SBATCH --partition=saarman-np
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00
#SBATCH --mem=16G
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="remove_samples"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load bcftools
module load htslib

VCF_IN=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf/Culex_stage2_bias_filtered.vcf.gz
OUT_DIR=/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_vcf
PREFIX=Culex_WGS_61samp

echo "=== Sample Removal: Low Coverage / Poor Mapping ==="
echo "Input: $VCF_IN"
echo "Start time: $(date)"

echo "Samples before removal:"
bcftools query -l $VCF_IN | wc -l

# Create sample removal file
REMOVE_FILE=${OUT_DIR}/samples_to_remove.txt
cat > $REMOVE_FILE << 'EOF'
UTCO_132_137_056
BE_201_191_002
SLC_053_141_052
WMAD_007_112_081
EOF

bcftools view \
    -S ^${REMOVE_FILE} \
    --force-samples \
    $VCF_IN | \
    bgzip > ${OUT_DIR}/${PREFIX}_stage2_samplefiltered.vcf.gz

bcftools index ${OUT_DIR}/${PREFIX}_stage2_samplefiltered.vcf.gz

echo ""
echo "Samples after removal:"
bcftools query -l ${OUT_DIR}/${PREFIX}_stage2_samplefiltered.vcf.gz | wc -l
echo ""
echo "Remaining samples:"
bcftools query -l ${OUT_DIR}/${PREFIX}_stage2_samplefiltered.vcf.gz

echo ""
echo "=== Sample Removal Complete ==="
echo "End time: $(date)"
echo ""
echo "Samples removed (4 total):"
echo "  UTCO_132_137_056 - 1.11x, 22.84% mapping (very low coverage + poor mapping)"
echo "  BE_201_191_002   - 1.54x, 46.12% mapping (very low coverage)"
echo "  SLC_053_141_052  - 2.17x, 42.00% mapping (very low coverage)"
echo "  WMAD_007_112_081 - 4.43x, 57.45% mapping (below 4.5x cutoff)"
echo ""
echo "Samples retained despite borderline quality:"
echo "  SGE_011_106_087  - 4.48x, 74.44% mapping (kept for SGE population representation)"
echo "  WMAD_018_172_021 - 7.53x, 71.72% mapping (acceptable quality)"
