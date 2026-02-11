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
        
        # Run samtools coverage (Python 3.6 compatible)
        try:
            result = subprocess.Popen(
                ['samtools', 'coverage', filepath],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            stdout, stderr = result.communicate()
            
            if result.returncode != 0:
                print(f"Error processing {sample}: {stderr}")
                results.append((sample, 0))
                continue
            
            # Parse output to get weighted mean coverage
            total_bases = 0
            total_depth = 0
            
            for line in stdout.strip().split('\n')[1:]:  # Skip header
                fields = line.split('\t')
                if len(fields) >= 7:
                    meandepth = float(fields[6])
                    endpos = int(fields[2])
                    startpos = int(fields[1])
                    length = endpos - startpos + 1
                    
                    total_bases += length
                    total_depth += meandepth * length
            
            mean_depth = total_depth / total_bases if total_bases > 0 else 0
            results.append((sample, mean_depth))
            
        except Exception as e:
            print(f"Error processing {sample}: {e}")
            results.append((sample, 0))

# Write results
with open(output_file, 'w') as out:
    out.write(f"{'Sample':<35} {'Mean_Depth':>12}\n")
    out.write("=" * 50 + "\n")
    
    for sample, depth in results:
        out.write(f"{sample:<35} {depth:>12.2f}x\n")

print(f"\nCoverage summary created: {output_file}")
print("\nShowing first 15 results:")
with open(output_file, 'r') as f:
    for i, line in enumerate(f):
        if i < 17:
            print(line.rstrip())
