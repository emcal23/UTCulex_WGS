#!/usr/bin/env python3

import os
import subprocess
import re

# Directory with BAM files
bam_dir = "/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_indexed"
output_file = os.path.join(bam_dir, "coverage_summary.txt")

print("Calculating coverage for all samples (this may take a few minutes)...")

results = []

# Process each BAM file
for filename in sorted(os.listdir(bam_dir)):
    if filename.endswith('.markdup.bam'):
        sample = filename.replace('.markdup.bam', '')
        filepath = os.path.join(bam_dir, filename)
        
        print(f"Processing {sample}...")
        
        # Run samtools coverage
        try:
            result = subprocess.run(
                ['samtools', 'coverage', filepath],
                capture_output=True,
                text=True,
                check=True
            )
            
            # Parse output to get weighted mean coverage
            total_bases = 0
            total_depth = 0
            
            for line in result.stdout.strip().split('\n')[1:]:  # Skip header
                fields = line.split('\t')
                if len(fields) >= 7:
                    numreads = int(fields[3])
                    covbases = int(fields[4])
                    coverage = float(fields[5])
                    meandepth = float(fields[6])
                    endpos = int(fields[2])
                    startpos = int(fields[1])
                    length = endpos - startpos + 1
                    
                    total_bases += length
                    total_depth += meandepth * length
            
            mean_depth = total_depth / total_bases if total_bases > 0 else 0
            results.append((sample, mean_depth))
            
        except subprocess.CalledProcessError as e:
            print(f"Error processing {sample}: {e}")
            results.append((sample, 0))

# Write results
with open(output_file, 'w') as out:
    out.write(f"{'Sample':<35} {'Mean_Depth':>12}\n")
    out.write("=" * 50 + "\n")
    
    for sample, depth in results:
        out.write(f"{sample:<35} {depth:>12.2f}x\n")

print(f"\nCoverage summary created: {output_file}")
print("\nShowing results:")
with open(output_file, 'r') as f:
    print(f.read())
