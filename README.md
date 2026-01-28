Path to WGS data in CHPC /uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_scripts

# UTCulex_WGS
Whole Genome Sequencing data for Culex pipiens complex specimen from Utah

65 mosquitoes were analyzed using whole-genome sequencing (WGS) at 15× coverage with 40 million reads

Potential Workflow 

Step 1 — QC array job
fastqc on raw reads, produce MultiQC report

Step 2 — Align array job
bwa mem to align to Cx pipiens reference and trims
  *Is it possiblle or helpful to add other references as outgroups?

Step 3 - Remove PCR duplicates 
samtools  index, markdups, and flagstat

Step 4 — Variant calling 
bcftools

Step 5 - Filtering
