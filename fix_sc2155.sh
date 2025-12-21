#!/bin/bash
# This script fixes SC2155 by separating declaration and assignment

file="install-taxi-system.sh"

# Pattern: local var=$(command)
# We'll use a Python script for more reliable replacement

python3 << 'PYTHON'
import re

with open('install-taxi-system.sh', 'r') as f:
    content = f.read()

# Fix patterns like: local var=$(...)
# Replace with: local var; var=$(...)
patterns = [
    (r'local credentials_file="\$\(date', 'local credentials_file\n    credentials_file="$(date'),
    (r'local exposed_ports=\$\(netstat', 'local exposed_ports\n    exposed_ports=$(netstat'),
    (r'local socket_perms=\$\(stat', 'local socket_perms\n    socket_perms=$(stat'),
    (r'local pids=\$\(lsof', 'local pids\n            pids=$(lsof'),
    (r'local process_name=\$\(ps', 'local process_name\n                    process_name=$(ps'),
]

for old_pattern, new_pattern in patterns:
    content = re.sub(old_pattern, new_pattern, content)

with open('install-taxi-system.sh', 'w') as f:
    f.write(content)

print("SC2155 fixes applied")
PYTHON
