#!/usr/bin/perl

use strict;
use warnings;
use Parallel::ForkManager;

my $max = 2;  # Set the maximum number of parallel processes to 1 for testing, target is 20
my $pm = Parallel::ForkManager->new($max);  # Create a new Parallel::ForkManager object with the specified maximum

# Path to the reference genome file
my $genome = "/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/cx_ddRAD_bwa/ref/Cpip29_nodeb_gfill_mito.fasta";

# Output directory
my $output_dir = "/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_bwa";

# Path to bwa-mem2 and samtools binary
my $bwa = "/uufs/chpc.utah.edu/sys/installdir/r8/bwa-mem/2.2.1-smem_alloc/bwa-mem2.avx2";
#my $bwa = "bwa-mem2"; #module loaded in SLURM
#my $bwa = "/uufs/chpc.utah.edu/sys/installdir/bwa/2.2.1/bin/bwa";
my $samtools = "/uufs/chpc.utah.edu/sys/installdir/samtools/1.16/bin/samtools";
#my $samtools = "samtools"; #module loaded in SLURM

# Directory containing raw FASTQ files
my $raw_dir = "/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_raw";

# Get all R1 FASTQs in that directory
opendir(my $dh, $raw_dir) or die "Can't open $raw_dir: $!";
my @fq1_files = grep { /_R1_001\.fastq\.gz$/ } readdir($dh);
closedir($dh);


FILES:
foreach my $fq1 (@fq1_files) {
    $pm->start and next FILES;

    # Full path to R1
    my $fq1_path = "$raw_dir/$fq1";

    # Extract identifier
    $fq1 =~ m/(.+)_R1_001\.fastq\.gz$/ or die "failed match for file $fq1\n";
    my $ind = $1;

    # Full path to R2
    my $fq2_path = "$raw_dir/${ind}_R2_001.fastq.gz";
    die "Missing R2 file for $ind\n" unless -e $fq2_path;

    # Run BWA + samtools
    my $cmd = "$bwa mem -M -t 1 $genome $fq1_path $fq2_path | $samtools view -b | $samtools sort --threads 1 -o ${output_dir}/${ind}.bam";
    system($cmd) == 0 or die "system $cmd failed: $?";

    print "Alignment completed for $ind\n";
    $pm->finish;
}

$pm->wait_all_children;



# bwa-mem2 mem #options
#-----------------------------
#Executing in AVX512 mode!!
#-----------------------------
#Usage: bwa2 mem [options] <idxbase> <in1.fq> [in2.fq]
#Options:
#  Algorithm options:
#    -o STR        Output SAM file name
#    -t INT        number of threads [1]
#    -k INT        minimum seed length [19]
#    -w INT        band width for banded alignment [100]
#    -d INT        off-diagonal X-dropoff [100]
#    -r FLOAT      look for internal seeds inside a seed longer than {-k} * FLOAT [1.5]
#    -y INT        seed occurrence for the 3rd round seeding [20]
#    -c INT        skip seeds with more than INT occurrences [500]
#    -D FLOAT      drop chains shorter than FLOAT fraction of the longest overlapping chain [0.50]
#    -W INT        discard a chain if seeded bases shorter than INT [0]
#    -m INT        perform at most INT rounds of mate rescues for each read [50]
#    -S            skip mate rescue
#    -o            output file name missing
#    -P            skip pairing; mate rescue performed unless -S also in use
#Scoring options:
#   -A INT        score for a sequence match, which scales options -TdBOELU unless overridden [1]
#   -B INT        penalty for a mismatch [4]
#   -O INT[,INT]  gap open penalties for deletions and insertions [6,6]
#   -E INT[,INT]  gap extension penalty; a gap of size k cost '{-O} + {-E}*k' [1,1]
#   -L INT[,INT]  penalty for 5'- and 3'-end clipping [5,5]
#   -U INT        penalty for an unpaired read pair [17]
#Input/output options:
#   -p            smart pairing (ignoring in2.fq)
#   -R STR        read group header line such as '@RG\tID:foo\tSM:bar' [null]
#   -H STR/FILE   insert STR to header if it starts with @; or insert lines in FILE [null]
#   -j            treat ALT contigs as part of the primary assembly (i.e. ignore <idxbase>.alt file)
#   -v INT        verbose level: 1=error, 2=warning, 3=message, 4+=debugging [3]
#   -T INT        minimum score to output [30]
#   -h INT[,INT]  if there are <INT hits with score >80% of the max score, output all in XA [5,200]
#   -a            output all alignments for SE or unpaired PE
#   -C            append FASTA/FASTQ comment to SAM output
#   -V            output the reference FASTA header in the XR tag
#   -Y            use soft clipping for supplementary alignments
#   -M            mark shorter split hits as secondary
#   -I FLOAT[,FLOAT[,INT[,INT]]]
#                 specify the mean, standard deviation (10% of the mean if absent), max
#                 (4 sigma from the mean if absent) and min of the insert size distribution.
#                 FR orientation only. [inferred]
#Note: Please read the man page for detailed description of the command line and options.
#No. of OMP threads: 0
#Processor is runnig @2095.190746 MHz
#Runtime profile:
#
#	 Time taken for main_mem function: 0.00 Sec
#
#	IO times (sec) :
#	Reading IO time (reads) avg: 0.00, (0.00, 0.00)
#	Writing IO time (SAM) avg: 0.00, (0.00, 0.00)
#	Reading IO time (Reference Genome) avg: 0.00, (0.00, 0.00)
#	Index read time avg: 0.00, (0.00, 0.00)
#
#	Overall time (sec) (Excluding Index reading time):
#	PROCESS() (Total compute time + (read + SAM) IO time) : 0.00
#	MEM_PROCESS_SEQ() (Total compute time (Kernel + SAM)), avg: 0.00, (0.00, 0.00)
#
#	 SAM Processing time (sec):
#	--WORKER_SAM avg: 0.00, (0.00, 0.00)
#
#	Kernels' compute time (sec):
#	Total kernel (smem+sal+bsw) time avg: 0.00, (0.00, 0.00)
#		SMEM compute avg: -nan, (0.00, 477283.51)
#		SAL compute avg: -nan, (0.00, 477283.51)
#		BSW time, avg: -nan, (0.00, 477283.51)
#
#	Total allocs: 0 = 0 out total requests: 0, Rate: -nan
#
#Important parameter settings: 
#	BATCH_SIZE: 512
#	MAX_SEQ_LEN_REF: 256
#	MAX_SEQ_LEN_QER: 128
#	MAX_SEQ_LEN8: 128
#	SEEDS_PER_READ: 500
#	SIMD_WIDTH8 X: 64
#	SIMD_WIDTH16 X: 32
#	AVG_SEEDS_PER_READ: 64#
