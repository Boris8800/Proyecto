#!/usr/bin/env python3
import re

# Read the script
with open('install-taxi-system.sh', 'r') as f:
    lines = f.readlines()

# Find where functions end (first non-function, non-comment line after shebang)
func_end = 0
in_function = False
brace_count = 0

# Find the end of function definitions
for i, line in enumerate(lines):
    if re.match(r'^[a-z_]+\(\) \{', line):
        in_function = True
        brace_count = 0
    
    if in_function:
        brace_count += line.count('{') - line.count('}')
        if brace_count == 0 and '{' in line:
            # Function ended, look for the next one
            for j in range(i+1, len(lines)):
                if re.match(r'^[a-z_]+\(\) \{', lines[j]):
                    break
                elif lines[j].strip() and not lines[j].strip().startswith('#'):
                    # Found non-function code
                    func_end = j
                    break
            if func_end > 0:
                break

print(f"Functions end at line {func_end}")
print(f"First non-function line: {lines[func_end-1].strip()[:60] if func_end > 0 else 'N/A'}")
