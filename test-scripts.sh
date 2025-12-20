#!/bin/bash
# Comprehensive test script to verify all taxi installation scripts

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  TAXI SYSTEM SCRIPTS VALIDATION TEST${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}\n"

test_count=0
pass_count=0
fail_count=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((test_count++))
    echo -n "Test $test_count: $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((pass_count++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((fail_count++))
        return 1
    fi
}

# Syntax Tests
echo -e "\n${YELLOW}[1] Syntax Validation${NC}"
run_test "install-taxi-system.sh syntax" "bash -n install-taxi-system.sh"
run_test "taxi-install.sh syntax" "bash -n taxi-install.sh"
run_test "taxi_fixed.sh syntax" "bash -n taxi_fixed.sh"
run_test "nginx-menu.sh syntax" "bash -n nginx-menu.sh"
run_test "src/main.sh syntax" "bash -n src/main.sh"

# Variable Definition Tests
echo -e "\n${YELLOW}[2] Variable Definition Tests${NC}"
run_test "Color variables defined" "grep -q 'RED=.*033' install-taxi-system.sh"
run_test "NC variable defined" "grep -q 'NC=.*033.*0m' install-taxi-system.sh"
run_test "Logging functions defined" "grep -q '^log_step()' install-taxi-system.sh"

# Function Definition Tests
echo -e "\n${YELLOW}[3] Function Definition Tests${NC}"
run_test "main_installer function exists" "grep -q '^main_installer()' install-taxi-system.sh"
run_test "print_banner function exists" "grep -q '^print_banner()' install-taxi-system.sh"
run_test "check_space function exists" "grep -q '^check_space()' install-taxi-system.sh"

# Logic Tests
echo -e "\n${YELLOW}[4] Logic & Structure Tests${NC}"
run_test "Shebang present" "head -1 install-taxi-system.sh | grep -q '^#!/bin/bash'"
run_test "Error handling set" "grep -q 'set -euo pipefail' install-taxi-system.sh"
run_test "Script has execution entry point" "grep -q 'main_installer.*@' install-taxi-system.sh"

# Dependency Checks
echo -e "\n${YELLOW}[5] Dependency References${NC}"
run_test "Docker installation referenced" "grep -qi 'docker' install-taxi-system.sh"
run_test "User creation referenced" "grep -q 'useradd.*taxi' install-taxi-system.sh"
run_test "Directory creation referenced" "grep -q 'mkdir.*taxi' install-taxi-system.sh"

# Runtime Safety Tests
echo -e "\n${YELLOW}[6] Runtime Safety Tests${NC}"
run_test "IP detection before use" "grep -n 'IP=\$(hostname' install-taxi-system.sh | head -1 | cut -d: -f1 | xargs -I {} grep -q 'IP=' install-taxi-system.sh"
run_test "Taxi user check before chown" "grep -B5 'chown.*taxi:taxi' install-taxi-system.sh | grep -q 'id taxi\|useradd'"

# Summary
echo -e "\n${YELLOW}═══════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  TEST SUMMARY${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo -e "Total Tests: $test_count"
echo -e "${GREEN}Passed: $pass_count${NC}"
echo -e "${RED}Failed: $fail_count${NC}"

if [ $fail_count -eq 0 ]; then
    echo -e "\n${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}Scripts are ready for execution on Ubuntu server.${NC}\n"
    exit 0
else
    echo -e "\n${RED}✗ SOME TESTS FAILED!${NC}"
    echo -e "${YELLOW}Review the failed tests above.${NC}\n"
    exit 1
fi
