#!/usr/bin/env python3

import os
import re

# Directory with flagstat files
flagstat_dir = "/uufs/chpc.utah.edu/common/home/u1055819/saarman-group/Cx_WGS/Cx_WGS_final"

# Output file
output_file = os.path.join(flagstat_dir, "mergedflagstat_summary_clean.txt")

# Open output file
with open(output_file, 'w') as out:
    # Write header
    out.write(f"{'Sample':<35} {'Total':>12} {'Mapped':>12} {'Mapped%':>10} {'Duplicates':>12} {'Dup%':>8}\n")
    out.write("=" * 95 + "\n")
    
    # Process each flagstat file
    for filename in sorted(os.listdir(flagstat_dir)):
        if filename.endswith('.flagstat.txt'):
            filepath = os.path.join(flagstat_dir, filename)
            sample = filename.replace('.flagstat.txt', '')
            
            with open(filepath, 'r') as f:
                content = f.read()
                
                # Extract values
                total_match = re.search(r'(\d+) \+ \d+ in total', content)
                mapped_match = re.search(r'(\d+) \+ \d+ mapped \(([0-9.]+)%', content)
                dup_match = re.search(r'(\d+) \+ \d+ duplicates', content)
                
                if total_match and mapped_match and dup_match:
                    total = int(total_match.group(1))
                    mapped = int(mapped_match.group(1))
                    mapped_pct = float(mapped_match.group(2))
                    duplicates = int(dup_match.group(1))
                    
                    # Calculate duplicate percentage
                    dup_pct = (duplicates / total) * 100 if total > 0 else 0
                    
                    # Write to file
                    out.write(f"{sample:<35} {total:>12,} {mapped:>12,} {mapped_pct:>9.2f}% {duplicates:>12,} {dup_pct:>7.2f}%\n")

print(f"Summary created: {output_file}")
print("\nShowing first 10 lines:")
with open(output_file, 'r') as f:
    for i, line in enumerate(f):
        if i < 12:  # header + separator + 10 samples
            print(line.rstrip())
