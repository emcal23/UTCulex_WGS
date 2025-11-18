#!/bin/bash
#SBATCH --partition=saarman-shared-np
#SBATCH --account=saarman-np
#SBATCH --time=24:00:00
#SBATCH --mem=24576
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --job-name="downloadfastq"
#SBATCH --mail-user=emily.calhoun@usu.edu
#SBATCH --mail-type=BEGIN,END,FAIL

module load aria2

# Base working directory
WORKDIR="/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS"
RAW_DIR="$WORKDIR/Cx_WGSraw"
mkdir -p "$RAW_DIR"
cd "$RAW_DIR"

# File to store all URLs
urls_file="urls.txt"
> $urls_file  # clear if it exists

# Function to generate URLs
generate_urls() {
    base_url=$1
    # Get subdirectories
    curl -s "$base_url" | grep -o 'href="[^"]*"' | sed 's/href="//;s/"//' | while read subdir; do
        # Only directories end with /
        if [[ $subdir == */ ]]; then
            # List files in that subdirectory
            curl -s "$base_url$subdir" | grep -o 'href="[^"]*"' | sed 's/href="//;s/"//' | grep -E "\.fastq$|\.fastq\.gz$" | while read file; do
                # Construct full URL
                echo "$base_url$subdir$file" >> "$urls_file"
            done
        fi
    done
}

# Generate URLs for both datasets
generate_urls "http://fcb.ycga.yale.edu:3010/I3uFrRgyau39sdKqRrppFR57qz1bue1/sample_dir_000019491/"
generate_urls "http://fcb.ycga.yale.edu:3010/TKlineFkigyao4idvY09P1b0xrr__cg/sample_dir_000019646/"

# Download each file into its sample folder
while read url; do
    filename=$(basename "$url")
    # Extract sample ID (everything before _S<number>_L<number>_R1/2_001.fastq.gz)
    sample=$(echo "$filename" | sed -E 's/(_S[0-9]+_L[0-9]+_R[12]_001\.fastq\.gz)//')
    mkdir -p "$RAW_DIR/$sample"
    aria2c -c -x 8 -j 4 -d "$RAW_DIR/$sample" "$url"
done < "$urls_file"
