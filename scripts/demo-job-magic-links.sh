#!/bin/bash

# Job Magic Links - Demo & Test Script
# Tests the complete workflow

set -e

# Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
NC='\e[0m'

API_URL="http://localhost:3334/api/job-magic-links"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Job Magic Links - Complete Workflow Demo              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
printf "\n"

# Check if API is running
echo -e "${YELLOW}[1] Checking if Job Magic Links API is running...${NC}"
if ! curl -s http://localhost:3334/health > /dev/null 2>&1; then
    echo -e "${RED}[ERROR] API not running on port 3334${NC}"
    echo "Start it with: cd /workspaces/Proyecto/web/api && node job-magic-links.js"
    exit 1
fi
echo -e "${GREEN}[OK] API is running!${NC}"
printf "\n"

# Create a magic link for a job
echo -e "${YELLOW}[2] Creating magic link for a paid job...${NC}"

JOB_ID="DEMO-$(date +%s)"
RESPONSE=$(curl -s -X POST $API_URL/create-for-job \
  -H "Content-Type: application/json" \
  -d '{
    "jobId": "'$JOB_ID'",
    "driverEmail": "demo-driver@example.com",
    "driverName": "Demo Driver",
    "driverPhone": "+1-555-0123",
    "pickupAddress": "Times Square, New York, NY",
    "pickupLat": 40.7580,
    "pickupLng": -73.9855,
    "dropoffAddress": "Central Park, New York, NY",
    "dropoffLat": 40.7829,
    "dropoffLng": -73.9654,
    "jobTime": "2025-12-25T18:00:00Z",
    "fare": 35.50,
    "expiryHours": 24
  }')

echo -e "${GREEN}Response:${NC}"
echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"

# Extract token from response
TOKEN=$(echo "$RESPONSE" | jq -r '.token' 2>/dev/null)
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo -e "${RED}[ERROR] Failed to extract token${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Magic link created!${NC}"
echo -e "${YELLOW}Token: ${NC}$TOKEN"
echo -e "${YELLOW}Job ID: ${NC}$JOB_ID"
printf "\n"

# Validate the token (driver clicks the link)
echo -e "${YELLOW}[3] Validating token (driver clicks magic link)...${NC}"

VALIDATE_RESPONSE=$(curl -s $API_URL/validate/$TOKEN)
echo -e "${GREEN}Response:${NC}"
echo "$VALIDATE_RESPONSE" | jq . 2>/dev/null || echo "$VALIDATE_RESPONSE"

SESSION_TOKEN=$(echo "$VALIDATE_RESPONSE" | jq -r '.sessionToken' 2>/dev/null)
if [ -z "$SESSION_TOKEN" ] || [ "$SESSION_TOKEN" = "null" ]; then
    echo -e "${RED}[ERROR] Failed to extract session token${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Token validated and session created!${NC}"
echo -e "${YELLOW}Session Token: ${NC}$SESSION_TOKEN"
printf "\n"

# Update driver location
echo -e "${YELLOW}[4] Simulating driver location updates...${NC}"

for i in {1..3}; do
    echo "  Update $i/3..."
    
    # Simulate slightly different coordinates
    LAT=$(echo "40.7128 + (0.$RANDOM / 32768) * 0.01" | bc)
    LNG=$(echo "-74.0060 + (0.$RANDOM / 32768) * 0.01" | bc)
    
    curl -s -X POST $API_URL/update-location/$JOB_ID \
      -H "Content-Type: application/json" \
      -d '{
        "latitude": '$LAT',
        "longitude": '$LNG',
        "accuracy": 5.2,
        "heading": 180,
        "speed": 15.5,
        "sessionToken": "'$SESSION_TOKEN'"
      }' > /dev/null
    
    sleep 1
done

echo -e "${GREEN}[OK] Location updates sent!${NC}"
printf "\n"

# Get latest driver location
echo -e "${YELLOW}[5] Retrieving latest driver location...${NC}"

LOCATION_RESPONSE=$(curl -s $API_URL/driver-location/$JOB_ID)
echo -e "${GREEN}Response:${NC}"
echo "$LOCATION_RESPONSE" | jq . 2>/dev/null || echo "$LOCATION_RESPONSE"

echo -e "${GREEN}[OK] Driver location retrieved!${NC}"
printf "\n"

# Get job details
echo -e "${YELLOW}[6] Retrieving job details...${NC}"

JOB_RESPONSE=$(curl -s $API_URL/job/$JOB_ID)
echo -e "${GREEN}Response:${NC}"
echo "$JOB_RESPONSE" | jq . 2>/dev/null || echo "$JOB_RESPONSE"

echo -e "${GREEN}[OK] Job details retrieved!${NC}"
printf "\n"

# Complete the job
echo -e "${YELLOW}[7] Completing the job...${NC}"

COMPLETE_RESPONSE=$(curl -s -X POST $API_URL/complete-job/$JOB_ID \
  -H "Content-Type: application/json" \
  -d '{"sessionToken": "'$SESSION_TOKEN'"}')

echo -e "${GREEN}Response:${NC}"
echo "$COMPLETE_RESPONSE" | jq . 2>/dev/null || echo "$COMPLETE_RESPONSE"

echo -e "${GREEN}[OK] Job completed!${NC}"
printf "\n"

# Get statistics
echo -e "${YELLOW}[8] Retrieving statistics...${NC}"

STATS_RESPONSE=$(curl -s $API_URL/stats)
echo -e "${GREEN}Response:${NC}"
echo "$STATS_RESPONSE" | jq . 2>/dev/null || echo "$STATS_RESPONSE"

echo -e "${GREEN}[OK] Statistics retrieved!${NC}"
printf "\n"

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   DEMO COMPLETED ✅                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
printf "\n"

echo -e "${GREEN}Summary:${NC}"
echo "  Job ID: $JOB_ID"
echo "  Magic Token: $TOKEN"
echo "  Session Token: $SESSION_TOKEN"
printf "\n"

echo -e "${YELLOW}What happened:${NC}"
echo "  1. Created magic link for paid job"
echo "  2. Driver validated link (got session)"
echo "  3. Driver sent location updates"
echo "  4. Retrieved driver location for tracking"
echo "  5. Got job details"
echo "  6. Marked job as completed"
echo "  7. Retrieved system statistics"
printf "\n"

echo -e "${YELLOW}Next steps:${NC}"
echo "  - Open driver page: http://localhost:3001/driver/job?token=$TOKEN"
echo "  - Check logs: tail -f /tmp/job-magic-links.log"
echo "  - View database: sqlite3 /root/job_magic_links.db"
echo "  - Read full guide: docs/JOB_MAGIC_LINKS_GUIDE.md"
printf "\n"

echo -e "${GREEN}✓ Demo completed successfully!${NC}"
