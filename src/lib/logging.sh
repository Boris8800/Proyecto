#!/bin/bash
log_header() { echo -e "${YELLOW}$1${NC}"; }
log_step() { echo -e "${GREEN}$1${NC}"; }
log_error() { echo -e "${RED}ERROR: $1${NC}"; }
log_success() { echo -e "${GREEN}$1${NC}"; }
