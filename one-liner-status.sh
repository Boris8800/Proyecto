#!/bin/bash
# SwiftCab One-Liner Status Commands
# Copy and paste any of these in your Ubuntu terminal

# Simple status check
echo "SWIFTCAB STATUS" && echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" && echo "Docker:" && docker ps --filter "label!=unused" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null && echo "" && echo "Ports:" && for port in 3000 3001 3002 3003 5432 6379 27017; do echo -n "Port $port: "; ss -tlnp 2>/dev/null | grep -q ":$port " && echo "✓ OPEN" || echo "✗ CLOSED"; done && echo "" && echo "Connectivity:" && curl -s -I http://localhost:3003 2>/dev/null | head -1 && echo "Timestamp: $(date)"
