Path to WGS data in CHPC /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_scripts

# UTCulex_WGS
Whole Genome Sequencing data for Culex pipiens complex specimen from Utah

65 mosquitoes were analyzed using whole-genome sequencing (WGS) at 15× coverage with 40 million reads

Potential Workflow 

Step 1 — QC array job
fastqc on raw reads, produce MultiQC report

Step 2 — Trim array job
fastp trimming, fastqc on trimmed reads

Step 3 — Align array job
bwa mem, samtools sort

Step 4 — Per-sample gVCF array job
GATK HaplotypeCaller → .g.vcf.gz

Step 5 — Joint steps (not arrays)
GenomicsDBImport / CombineGVCFs, GenotypeGVCFs, VCF filtering, PCA/ADMIXTURE/etc.
